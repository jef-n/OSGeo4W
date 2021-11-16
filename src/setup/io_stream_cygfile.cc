/*
 * Copyright (c) 2001, Robert Collins.
 *
 *     This program is free software; you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation; either version 2 of the License, or
 *     (at your option) any later version.
 *
 *     A copy of the GNU General Public License can be found at
 *     http://www.gnu.org/
 *
 * Written by Robert Collins  <rbtcollins@hotmail.com>
 *
 */

#include "win32.h"
#include "mklink2.h"
#include "filemanip.h"
#include "mkdir.h"
#include "mount.h"
#include "msg.h"

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <unistd.h>
#include <vector>

#include "io_stream_cygfile.h"
#include "IOStreamProvider.h"
#include "LogSingleton.h"
#include "String++.h"
#include "Window.h"


/* completely private iostream registration class */
class CygFileProvider : public IOStreamProvider
{
public:
  int exists (const std::string& path) const
    {return io_stream_cygfile::exists(path);}
  int remove (const std::string& path) const
    {return io_stream_cygfile::remove(path);}
  int mklink (const std::string& a , const std::string& b, io_stream_link_t c) const
    {return io_stream_cygfile::mklink(a,b,c);}
  io_stream *open (const std::string& a,const std::string& b) const
    {return new io_stream_cygfile (a, b);}
  ~CygFileProvider (){}
  int move (const std::string& a,const std::string& b) const
    {return io_stream_cygfile::move (a, b);}
  int mkdir_p (path_type_t isadir, const std::string& path) const
    {return cygmkdir_p (isadir, path);}
protected:
  CygFileProvider() // no creating this
    {
      io_stream::registerProvider (theInstance, "cygfile://");
    }
  CygFileProvider(CygFileProvider const &); // no copying
  CygFileProvider &operator=(CygFileProvider const &); // no assignment
private:
  static CygFileProvider theInstance;
};
CygFileProvider CygFileProvider::theInstance = CygFileProvider();


/* For set mtime */
#define FACTOR (0x19db1ded53ea710LL)
#define NSPERSEC 10000000LL

std::string io_stream_cygfile::cwd("/");

// Normalise a unix style path relative to
// cwd.
std::string
io_stream_cygfile::normalise (const std::string& unixpath)
{
  char *path,*tempout;

  if (unixpath.c_str()[0]=='/')
    {
      // rooted path
      path = new_cstr_char_array (unixpath);
      tempout = new_cstr_char_array (unixpath); // paths only shrink.
    }
  else
    {
      path = new_cstr_char_array (cwd + unixpath);
      tempout = new_cstr_char_array (cwd + unixpath); //paths only shrink.
    }

  // FIXME: handle .. depth tests to prevent / + ../foo/ stepping out
  // of the cygwin tree
  // FIXME: handle /./ sequences
  bool sawslash = false;
  char *outptr = tempout;
  for (char *ptr=path; *ptr; ++ptr)
    {
      if (*ptr == '/' && sawslash)
	--outptr;
      else if (*ptr == '/')
	sawslash=true;
      else
	sawslash=false;
      *outptr++ = *ptr;
    }
  std::string rv = tempout;
  delete[] path;
  delete[] tempout;
  return rv;
}

io_stream_cygfile::io_stream_cygfile (const std::string& name, const std::string& mode) : fp(), fname()
{
  errno = 0;
  if (!name.size() || !mode.size())
  {
    log(LOG_TIMESTAMP) << "io_stream_cygfile: Bad parameters" << endLog;
    return;
  }

  /* do this every time because the mount points may change due to fwd/back button use...
   * TODO: make this less...manual
   */
  if (!get_root_dir ().size())
  {
    /* TODO: assign a errno for "no root dir set:} " */
    log(LOG_TIMESTAMP) << "io_stream_cygfile " << name << ": root dir empty" << endLog;
    return;
  }

  fname = cygpath (normalise(name));
  fp = fopen (fname.c_str(), mode.c_str());
  if (!fp)
  {
    lasterr = errno;
    log(LOG_TIMESTAMP) << "io_stream_cygfile: fopen(" << name << ") failed " << errno << " "
      << strerror(errno) << endLog;
  }
}

io_stream_cygfile::~io_stream_cygfile ()
{
  if (fp)
    fclose (fp);
}

/* Static members */
int
io_stream_cygfile::exists (const std::string& path)
{
  if (!get_root_dir ().size())
    return 0;

  std::string thePath = cygpath (normalise(path));
  DWORD attr = GetFileAttributesA (thePath.c_str());
  if (attr != INVALID_FILE_ATTRIBUTES)
    return 1;
  return 0;
}

int
io_stream_cygfile::remove (const std::string& path)
{
  if (!path.size())
    return 1;

  if (!get_root_dir ().size())
    /* TODO: assign a errno for "no root dir set :} " */
    return 1;

  std::string thePath = cygpath (normalise(path));

  unsigned long w = GetFileAttributesA (thePath.c_str());
  if (w != INVALID_FILE_ATTRIBUTES && w & FILE_ATTRIBUTE_DIRECTORY)
    {
      std::string tmp;
      int i = 0;
      do
        {
          tmp = Window::sprintf( "%s.old-%d", thePath.c_str(), ++i );
	}
      while (GetFileAttributesA (tmp.c_str()) != INVALID_FILE_ATTRIBUTES);
      msg( "warning: moving directory \"%s\" out of the way.\n",
           thePath.c_str() );
      MoveFileA (thePath.c_str(), tmp.c_str());
    }
  return io_stream::remove (std::string ("file://") + thePath.c_str());
}

int
io_stream_cygfile::mklink (const std::string& _from, const std::string& _to,
			   io_stream_link_t linktype)
{
  if (!_from.size() || !_to.size())
    return 1;
  std::string from(normalise(_from));
  std::string to (normalise(_to));
  switch (linktype)
    {
    case IO_STREAM_SYMLINK:
      // symlinks are arbitrary targets, can be anything, and are
      // not subject to translation
      return mkcygsymlink (cygpath (from).c_str(), _to.c_str());
    case IO_STREAM_HARDLINK:
      {
	/* First try to create a real hardlink. */
	if (!mkcyghardlink (cygpath (from).c_str(), cygpath (to).c_str ()))
	  return 0;

	/* If creating a hardlink failed, we're probably on a filesystem
	   which doesn't support hardlinks.  If so, we also don't care for
	   permissions for now.  The filesystem is probably a filesystem
	   which doesn't support ACLs anyway. */

	/* textmode alert: should we translate when linking from an binmode to a
	   text mode mount and vice verca?
	 */
	io_stream *in = io_stream::open (std::string ("cygfile://") + to, "rb");
	if (!in)
	  {
	    log (LOG_TIMESTAMP) << "could not open " << to
              << " for reading in mklink" << endLog;
	    return 1;
	  }
	io_stream *out = io_stream::open (std::string ("cygfile://") + from, "wb");
	if (!out)
	  {
	    log (LOG_TIMESTAMP) << "could not open " << from
              << " for writing in mklink" << endLog;
	    delete in;
	    return 1;
	  }

	if (io_stream::copy (in, out))
	  {
	    log (LOG_TIMESTAMP) << "Failed to hardlink " << from << "->"
              << to << " during file copy." << endLog;
	    delete in;
	    delete out;
	    return 1;
	  }
	delete in;
	delete out;
	return 0;
      }
    }
  return 1;
}


/* virtuals */

ssize_t
io_stream_cygfile::read (void *buffer, size_t len)
{
  if (fp)
    return fread (buffer, 1, len, fp);
  return 0;
}

ssize_t
io_stream_cygfile::write (const void *buffer, size_t len)
{
  if (fp)
    return fwrite (buffer, 1, len, fp);
  return 0;
}

ssize_t
io_stream_cygfile::peek (void *buffer, size_t len)
{
  if (fp)
    {
      int pos = ftell (fp);
      ssize_t rv = fread (buffer, 1, len, fp);
      fseek (fp, pos, SEEK_SET);
      return rv;
    }
  return 0;
}

ssize_t
io_stream_cygfile::tell ()
{
  if (fp)
    {
      return ftell (fp);
    }
  return 0;
}

int
io_stream_cygfile::seek (long where, io_stream_seek_t whence)
{
  if (fp)
    {
      return fseek (fp, where, (int) whence);
    }
  lasterr = EBADF;
  return -1;
}

int
io_stream_cygfile::error ()
{
  if (fp)
    return ferror (fp);
  return lasterr;
}

int
cygmkdir_p (path_type_t isadir, const std::string& _name)
{
  if (!_name.size())
    return 1;
  std::string name(io_stream_cygfile::normalise(_name));

  if (!get_root_dir ().size())
    /* TODO: assign a errno for "no root dir set :} " */
    return 1;
  return mkdir_p (isadir == PATH_TO_DIR ? 1 : 0, cygpath (name).c_str());
}

int
io_stream_cygfile::set_mtime (time_t mtime)
{
  if (!fname.size())
    return 1;
  if (fp)
    fclose (fp);
  long long ftimev = mtime * NSPERSEC + FACTOR;
  FILETIME ftime;
  ftime.dwHighDateTime = ftimev >> 32;
  ftime.dwLowDateTime = ftimev & 0xffffffff;
  HANDLE h =
    CreateFileA (fname.c_str(), GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE,
                 0, OPEN_EXISTING,
		 FILE_ATTRIBUTE_NORMAL | FILE_FLAG_BACKUP_SEMANTICS, 0);
  if (h == INVALID_HANDLE_VALUE)
    return 1;
  SetFileTime (h, 0, 0, &ftime);
  CloseHandle (h);
  return 0;
}

int
io_stream_cygfile::move (const std::string& _from, const std::string& _to)
{
  if (!_from.size() || !_to.size())
    return 1;
  std::string from (normalise(_from));
  std::string to(normalise(_to));

  if (!get_root_dir ().size())
    /* TODO: assign a errno for "no root dir set :} " */
    return 1;
  return rename (cygpath (from).c_str(), cygpath (to).c_str());
}

size_t
io_stream_cygfile::get_size ()
{
  if (!fname.size() )
    return 0;
  HANDLE h;
  DWORD ret = 0;
  h = CreateFileA (fname.c_str(), GENERIC_READ,
		   FILE_SHARE_READ | FILE_SHARE_WRITE, 0, OPEN_EXISTING,
		   FILE_ATTRIBUTE_NORMAL | FILE_FLAG_BACKUP_SEMANTICS, 0);
  if (h != INVALID_HANDLE_VALUE)
    {
      ret = GetFileSize (h, NULL);
      CloseHandle (h);
    }
  return ret;
}
