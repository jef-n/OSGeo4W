/*
 * Copyright (c) 2000, 2001, Red Hat, Inc.
 *
 *     This program is free software; you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation; either version 2 of the License, or
 *     (at your option) any later version.
 *
 *     A copy of the GNU General Public License can be found at
 *     http://www.gnu.org/
 *
 * Written by DJ Delorie <dj@cygnus.com>
 *
 */

/* Built-in tar functionality.  See tar.h for usage. */

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <errno.h>

//#include "zlib/zlib.h"
#include "io_stream.h"
//#include "compress.h"
#include "archive.h"
#include "archive_tar.h"
#include "mkdir.h"
#include "LogSingleton.h"
#include "filemanip.h"

#include "String++.h"

static int err;

static char buf[512];

int _tar_verbose = 0;
FILE *_tar_vfile = 0;
#define vp if (_tar_verbose) fprintf
#define vp2 if (_tar_verbose>1) fprintf

archive_tar::archive_tar (io_stream * original)
{
  archive_children = 0;
  if (_tar_vfile == 0)
    _tar_vfile = stderr;

  vp2 (_tar_vfile, "tar: open `%p'\n", original);

  if (!original)
    {
      state.lasterr = EBADF;
      return;
    }
  state.parent = original;

  if (sizeof (state.tar_header) != 512)
    {
      /* drastic, but important */
      log (LOG_TIMESTAMP) << "compilation error: tar header struct not 512"
			  << " bytes (it's " << sizeof (state.tar_header)
			  << ")" << endLog;
      LogSingleton::GetInstance().exit (1);
    }
}

ssize_t
archive_tar::read (void *buffer, size_t len)
{
  return -1;
}

ssize_t
archive_tar::write (const void *buffer, size_t len)
{
  return 0;
}

ssize_t
archive_tar::peek (void *buffer, size_t len)
{
  return 0;
}

int
archive_tar::error ()
{
  return state.lasterr;
}

ssize_t
archive_tar::tell ()
{
  return state.file_offset;
}

int
archive_tar::seek (long where, io_stream_seek_t whence)
{
  /* seeking in the parent archive doesn't make sense. although we could
     map to files ? 
     Also, seeking might make sense for rewing..?? 
     */
  return -1; 
}

int
archive_tar::skip_file ()
{
  while (state.file_length > state.file_offset)
    {
      ssize_t len = state.parent->read (buf, sizeof buf);
      state.file_offset += sizeof buf;
      if (len != sizeof buf)
        return 1;
    }
  state.file_length = 0;
  state.file_offset = 0;
  state.header_read = 0;
  return 0;
}

const std::string
archive_tar::next_file_name ()
{
  char *c;

  if (state.header_read)
    {
      if (strlen (state.filename))
        return state.filename;
      else
        /* End of tar */
        return std::string();
    }

  ssize_t r = state.parent->read (&state.tar_header, sizeof state.tar_header);

  /* See if we're at end of file */
  if (r != sizeof state.tar_header)
    return std::string();

  /* See if the header is all zeros (i.e. last block) */
  int n = 0;
  for (r = sizeof (state.tar_header) / sizeof (int); r; r--)
    n |= ((int *) &state.tar_header)[r - 1];
  if (n == 0)
    return std::string();

  if (!state.have_longname && state.tar_header.typeflag != 'L')
    {
      memcpy (state.filename, state.tar_header.name, 100);
      state.filename[100] = 0;
    }
  else if (state.have_longname)
    state.have_longname = 0;

  sscanf (state.tar_header.size, "%zo", &state.file_length);
  state.file_offset = 0;

//  vp2 (_tar_vfile, "%c %9d %s\n", state.tar_header.typeflag,
//      state.file_length, state.filename);

  switch (state.tar_header.typeflag)
    {
    case 'L':			/* GNU tar long name extension */
      /* we read the 'file' into the long filename, then call back into here
       * to find out if the actual file is a real file, or a special file..
       */
      if (state.file_length > MAX_PATH)
	{
	  skip_file ();
	  fprintf (stderr, "error: long file name exceeds %d characters\n",
		   MAX_PATH);
	  err++;
	  state.parent->read (&state.tar_header, sizeof state.tar_header);
	  sscanf (state.tar_header.size, "%Io", &state.file_length);
	  state.file_offset = 0;
	  skip_file ();
	  return next_file_name ();
	}
      c = state.filename;
      /* FIXME: this should be a single read() call */
      while (state.file_length > state.file_offset)
	{
	  ssize_t need = std::min( state.file_length - state.file_offset, sizeof buf);
	  if ( state.parent->read (buf, sizeof buf) < (ssize_t) sizeof buf)
	    // FIXME: What's up with the "0"? It's probably a mistake, and
	    // should be "". It used to be written as 0, and was subject to a
	    // bizarre implicit conversion by the unwise String(int)
	    // constructor.
	    return "0";
	  memcpy (c, buf, need);
	  c += need;
	  state.file_offset += need;
	}
      *c = 0;
      state.have_longname = 1;
      return next_file_name ();

    case '3':			/* char */
    case '4':			/* block */
    case '6':			/* fifo */
      fprintf (stderr, "warning: not extracting special file %s\n",
	       state.filename);
      err++;
      return next_file_name ();

    case '0':			/* regular file */
    case 0:			/* regular file also */
    case '2':			/* symbolic link */
    case '5':			/* directory */
    case '7':			/* contiguous file */
      state.header_read = 1;
      return state.filename;

    case '1':			/* hard link, we just copy */
      state.header_read = 1;
      return state.filename;

    default:
      fprintf (stderr, "error: unknown (or unsupported) file type `%c'\n",
	       state.tar_header.typeflag);
      err++;
      /* fall through */
    case 'g':			/* POSIX.1-2001 global extended header */
    case 'x':			/* POSIX.1-2001 extended header */
      skip_file ();
      return next_file_name ();
    }
  return std::string();
}

archive_tar::~archive_tar ()
{
  if (state.parent)
    delete state.parent;
}

# if 0
static void
fix_time_stamp (char *path)
{
  int mtime;
  long long ftimev;
  FILETIME ftime;
  HANDLE h;

  sscanf (tar_header.mtime, "%o", &mtime);
  ftimev = mtime * NSPERSEC + FACTOR;
  ftime.dwHighDateTime = ftimev >> 32;
  ftime.dwLowDateTime = ftimev;
  h = CreateFileA (path, GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE,
		   0, OPEN_EXISTING,
		   FILE_ATTRIBUTE_NORMAL | FILE_FLAG_BACKUP_SEMANTICS, 0);
  if (h)
    {
      SetFileTime (h, 0, 0, &ftime);
      CloseHandle (h);
    }
}
#endif
archive_file_t
archive_tar::next_file_type ()
{
  switch (state.tar_header.typeflag)
    {
      /* regular files */
    case '0':
    case 0:
    case '7':
      return ARCHIVE_FILE_REGULAR;
    case '1':
      return ARCHIVE_FILE_HARDLINK;
    case '5':
      return ARCHIVE_FILE_DIRECTORY;
    case '2':
      return ARCHIVE_FILE_SYMLINK;
    default:
      return ARCHIVE_FILE_INVALID;
    }
}

const std::string
archive_tar::linktarget ()
{
  /* TODO: consider .. path traversal issues */
  if (next_file_type () == ARCHIVE_FILE_SYMLINK ||
      next_file_type () == ARCHIVE_FILE_HARDLINK)
    return state.tar_header.linkname;
  return std::string();
}

io_stream *
archive_tar::extract_file ()
{
  if (archive_children)
    return NULL;
  archive_tar_file *rv = new archive_tar_file (state);
  return rv;
}

time_t
archive_tar::get_mtime ()
{
  if (state.parent)
    return state.parent->get_mtime ();
  return 0;
}
