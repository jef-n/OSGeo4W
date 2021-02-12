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

/* Archive IO operations for bz2 files.  Derived from the fd convenience
   functions in the libbz2 package.  */

#include "compress_bz.h"

#include <stdexcept>
using namespace std;
#include <errno.h>
#include <string.h>

compress_bz::compress_bz (io_stream * parent) : peeklen (0), position (0)
{
  /* read only via this constructor */
  original = 0;
  lasterr = 0;
  if (!parent || parent->error ())
    {
      lasterr = EBADF;
      return;
    }
  original = parent;
  owns_original = true;

  initialisedOk = 0;
  endReached = 0;
  writing = 0;
  strm.bzalloc = 0;
  strm.bzfree = 0;
  strm.opaque = 0;
  int ret = BZ2_bzDecompressInit (&(strm), 0, 0);
  if (ret)
    {
      lasterr = ret;
      return;
    }
  strm.avail_in = 0;
  strm.next_in = 0;
  initialisedOk = 1;
}

ssize_t
compress_bz::read (void *buffer, size_t len)
{
  if (!initialisedOk || writing)
    {
      lasterr = EBADF;
      return -1;
    }
  if (endReached)
    return 0;
  if (len == 0)
    return 0;

  if (peeklen)
    {
      ssize_t tmplen = std::min (peeklen, len);
      peeklen -= tmplen;
      memcpy (buffer, peekbuf, tmplen);
      memmove (peekbuf, peekbuf + tmplen, tmplen);
      ssize_t tmpread = read (&((char *) buffer)[tmplen], len - tmplen);
      if (tmpread >= 0)
        return tmpread + tmplen;
      else
        return tmpread;
  }

  strm.avail_out = (unsigned int) len;
  strm.next_out = (char *) buffer;
  ssize_t rlen = 1;
  while (1)
    {
      int ret = BZ2_bzDecompress (&strm);

      if (strm.avail_in == 0 && rlen > 0)
	{
	  rlen = original->read (buf, 4096);
	  if (rlen < 0)
	    {
              lasterr = original->error ();
	      return -1;
	    }
	  strm.avail_in = (int) rlen;
	  strm.next_in = buf;
	}

      if (ret != BZ_OK && ret != BZ_STREAM_END)
	{
	  lasterr = ret;
	  return -1;
	}
      if (ret == BZ_OK && rlen == 0 && strm.avail_out)
	{
	  /* unexpected end of file */
	  lasterr = EIO;
	  return -1;
	}
      if (ret == BZ_STREAM_END)
	{
          /* Are we also at EOF? */
          if (rlen == 0)
            {
              endReached = 1;
            }
          else
            {
              /* BZ_SSTREAM_END but not at EOF means the file contains
                 another stream */
              BZ2_bzDecompressEnd (&strm);
              BZ2_bzDecompressInit (&(strm), 0, 0);
              /* This doesn't reinitialize strm, so strm.next_in still
                 points at strm.avail_in bytes left to decompress in buf */
            }

	  position += len - strm.avail_out;
	  return len - strm.avail_out;
	}
      if (strm.avail_out == 0)
	{
	  position += len;
	  return len;
	}
    }

  /* not reached */
  return 0;
}

ssize_t compress_bz::write (const void *buffer, size_t len)
{
  throw new logic_error ("compress_bz::write is not implemented");
}

ssize_t compress_bz::peek (void *buffer, size_t len)
{
  if (writing)
    {
      lasterr = EBADF;
      return -1;
    }

  /* can only peek 512 bytes */
  if (len > 512)
    {
      lasterr = ENOMEM;
      return -1;
    }

  if (len > peeklen)
    {
      size_t want = len - peeklen;
      ssize_t got = read (&peekbuf[peeklen], want);
      if (got >= 0)
        peeklen += got;
      else
	/* error */
	return got;
      
      /* we may have read less than requested. */
      memcpy (buffer, peekbuf, peeklen);
      return peeklen;
    }
  else
    {
      memcpy (buffer, peekbuf, len);
      return len;
    }
  return 0;
}

ssize_t
compress_bz::tell ()
{
  if (writing)
    throw new logic_error ("compress_bz::tell is not implemented "
                           "in writing mode");
  return position;
}

int
compress_bz::seek (long where, io_stream_seek_t whence)
{
  throw new logic_error ("compress_bz::seek is not implemented");
}

int
compress_bz::error ()
{
  return (int) lasterr;
}

int
compress_bz::set_mtime (time_t time)
{
  if (original)
    return original->set_mtime (time);
  return 1;
}

time_t
compress_bz::get_mtime ()
{
  if (original)
    return original->get_mtime ();
  return 0;
}

void
compress_bz::release_original ()
{
  owns_original = false;
}

compress_bz::~compress_bz ()
{
  if (initialisedOk)
    BZ2_bzDecompressEnd (&strm);
  if (original && owns_original)
    delete original;
}
