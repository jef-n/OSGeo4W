/*
 * Copyright (c) 2001, Robert Collins 
 *
 *     This program is free software; you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation; either version 2 of the License, or
 *     (at your option) any later version.
 *
 *     A copy of the GNU General Public License can be found at
 *     http://www.gnu.org/
 *
 * Written by Robert Collins <rbtcollins@hotmail.com>
 *
 */

/* An individual stream from a tar archive. */

#if 0
static const char *cvsid = "\n%%% $Id: archive_tar_file.cc,v 2.15 2011/04/24 11:19:48 jturney Exp $\n";
#endif

#include <errno.h>
#include <algorithm>

#include "io_stream.h"
#include "compress.h"
#include "archive.h"
#include "archive_tar.h"

archive_tar_file::archive_tar_file (tar_state & newstate)
  : read_something (false), state (newstate)
{
}

archive_tar_file::~archive_tar_file ()
{
  if (read_something)
    state.header_read = 0;
}

/* Virtual members */
ssize_t
archive_tar_file::read (void *buffer, size_t len)
{
  /* how many bytes do we want to give the user */
  ssize_t
    want = std::min (len, state.file_length - state.file_offset);
  /* how many do we need to read after that to line up the file pointer */
  ssize_t
    roundup = (512 - (want % 512)) % 512;
  read_something = true;
  if (want)
    {
      size_t need = want;
      char *p = (char *)buffer;
      while (need > 0)
        {
          ssize_t got = state.parent->read (p, need);
          if (got <= 0)
            {
              /* unexpected EOF or read error in the tar parent stream */
              /* the user can query the parent for the error */
              state.lasterr = EIO;
              return -1;
            }
          p += got;
          need -= got;
        }

      char throwaway[512];
      p = &throwaway[0];
      while (roundup > 0)
        {
          ssize_t got2 = state.parent->read (p, roundup);
          if (got2 <= 0)
            {
              /* unexpected EOF or read error in the tar parent stream */
              /* the user can query the parent for the error */
              state.lasterr = EIO;
              return -1;
            }
          p += got2;
          roundup -= got2;
        }

      state.file_offset += want;
      return want;
    }
  return 0;
}

/* provide data to (double duh!) */
ssize_t archive_tar_file::write (const void *buffer, size_t len)
{
  /* write not supported */
  state.lasterr = EBADF;
  return -1;
}

/* read data without removing it from the class's internal buffer */
ssize_t archive_tar_file::peek (void *buffer, size_t len)
{
  ssize_t
    want = std::min (len, state.file_length - state.file_offset);
  if (want)
    {
      ssize_t
	got = state.parent->peek (buffer, want);
      if (got == want)
	{
	  return got;
	}
      else
	{
	  /* unexpected EOF or read error in the tar parent stream */
	  /* the user can query the parent for the error */
	  state.lasterr = EIO;
	  return -1;
	}
    }
  return 0;
}

ssize_t
archive_tar_file::tell ()
{
  return state.file_offset;
}

int
archive_tar_file::seek (long where, io_stream_seek_t whence)
{
  /* nothing needs seeking here yet. Implement when needed 
   */
  state.lasterr = EINVAL;
  return -1;
}

/* try guessing this one */
int
archive_tar_file::error ()
{
  return state.lasterr;
}

time_t
archive_tar_file::get_mtime ()
{
  unsigned long mtime;
  sscanf (state.tar_header.mtime, "%lo", &mtime);
  return (time_t) mtime;
}
