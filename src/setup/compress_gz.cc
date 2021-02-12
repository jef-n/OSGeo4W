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

/* 
 * Portions copyright under the zlib licence - this class was derived from
 * gzio.c in that library.
 */

#include "compress_gz.h"

#include <stdexcept>
using namespace std;
#include <errno.h>
#include <memory.h>
#include <malloc.h>

#define HEAD_CRC     0x02	/* bit 1 set: header CRC present */
#define EXTRA_FIELD  0x04	/* bit 2 set: extra field present */
#define ORIG_NAME    0x08	/* bit 3 set: original file name present */
#define COMMENT      0x10	/* bit 4 set: file comment present */
#define RESERVED     0xE0	/* bits 5..7: reserved */


/* TODO make this a static member and federate the magic logic */
static int gz_magic[2] = { 0x1f, 0x8b };	/* gzip magic header */

/*
 * Predicate: the stream is open for read. For writing the class constructor variant with
 * mode must be called directly
 */
compress_gz::compress_gz (io_stream * parent)
{
  construct (parent, "r");
}

compress_gz::compress_gz (io_stream * parent, const char *openmode)
{
  construct (parent, openmode);
}

void
compress_gz::construct (io_stream * parent, const char *openmode)
{
  original = parent;
  owns_original = true;
  peeklen = 0;
  int err;
  int level = Z_DEFAULT_COMPRESSION;	/* compression level */
  int strategy = Z_DEFAULT_STRATEGY;	/* compression strategy */
  char *p = (char *) openmode;
  char fmode[80];		/* copy of openmode, without the compression level */
  char *m = fmode;

  stream.zalloc = (alloc_func) NULL;
  stream.zfree = (free_func) NULL;
  stream.opaque = (voidpf) NULL;
  stream.next_in = inbuf = NULL;
  stream.next_out = outbuf = NULL;
  stream.avail_in = stream.avail_out = 0;
  z_err = Z_OK;
  z_eof = 0;
  crc = crc32 (0L, Z_NULL, 0);
  msg = NULL;
  transparent = 0;

  mode = '\0';

  if (!parent)
    {
      z_err = Z_STREAM_ERROR;
      return;
    }
  
  do
    {
      if (*p == 'r')
        mode = 'r';
      if (*p == 'w' || *p == 'a')
        mode = 'w';
      if (*p >= '0' && *p <= '9')
        {
          level = *p - '0';
        }
      else if (*p == 'f')
        {
          strategy = Z_FILTERED;
        }
      else if (*p == 'h')
        {
          strategy = Z_HUFFMAN_ONLY;
        }
      else
        {
          *m++ = *p;		/* copy the mode */
        }
    }
  while (*p++ && m != fmode + sizeof (fmode));
  if (mode == '\0')
    {
      destroy ();
      z_err = Z_STREAM_ERROR;
      return;
    }


  if (mode == 'w')
    {
      err = deflateInit2 (&(stream), level,
			  Z_DEFLATED, -MAX_WBITS, 8, strategy);
      /* windowBits is passed < 0 to suppress zlib header */

      stream.next_out = outbuf = (Byte *) malloc (16384);
      if (err != Z_OK || outbuf == Z_NULL)
        {
          destroy ();
          z_err = Z_STREAM_ERROR;
          return;
        }
    }
  else
    {

      stream.next_in = inbuf = (unsigned char *) malloc (16384);
      err = inflateInit2 (&stream, -MAX_WBITS);
      /* windowBits is passed < 0 to tell that there is no zlib header.
       * Note that in this case inflate *requires* an extra "dummy" byte
       * after the compressed stream in order to complete decompression and
       * return Z_STREAM_END. Here the gzip CRC32 ensures that 4 bytes are
       * present after the compressed stream.
       */
      if (err != Z_OK || inbuf == Z_NULL)
        {
          destroy ();
          z_err = Z_STREAM_ERROR;
          return;
        }
    }
  stream.avail_out = 16384;

  errno = 0;
  if (mode == 'w')
    {
      /* Write a very simple .gz header:
       */
      char temp[20];
      sprintf (temp, "%c%c%c%c%c%c%c%c%c%c", gz_magic[0], gz_magic[1],
	       Z_DEFLATED, 0 /*flags */ , 0, 0, 0, 0 /*time */ ,
	       0 /*xflags */ , 0x0b);
      original->write (temp, 10);
      startpos = 10L;
      /* We use 10L instead of ftell(s->file) to because ftell causes an
       * fflush on some systems. This version of the library doesn't use
       * startpos anyway in write mode, so this initialization is not
       * necessary. 
       */
    }
  else
    {

      check_header ();		/* skip the .gz header */
      startpos = (original->tell () - stream.avail_in);
    }

  return;
}

/* ===========================================================================
   Outputs a long in LSB order to the given file
*/
void
compress_gz::putLong (unsigned long x)
{
  int n;
  for (n = 0; n < 4; n++)
    {
      unsigned char c = (unsigned char) (x & 0xff);
      original->write (&c, 1);
      x = x >> 8;
    }
}


uLong
compress_gz::getLong ()
{
  uLong x = (uLong) get_byte ();
  int c;

  x += ((uLong) get_byte ()) << 8;
  x += ((uLong) get_byte ()) << 16;
  c = get_byte ();
  if (c == EOF)
    z_err = Z_DATA_ERROR;
  x += ((uLong) c) << 24;
  return x;
}


ssize_t
compress_gz::read (void *buffer, size_t len)
{
  if (!len)
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

  Bytef *start = (Bytef *) buffer;	/* starting point for crc computation */
  Byte *next_out;		/* == stream.next_out but not forced far (for MSDOS) */

  if (mode != 'r')
    {
      z_err =  Z_STREAM_ERROR;
      return -1;
    }

  if (z_err == Z_DATA_ERROR || z_err == Z_ERRNO)
    return -1;
  if (z_err == Z_STREAM_END)
    return 0;			/* EOF */

  next_out = (Byte *) buffer;
  stream.next_out = (Bytef *) buffer;
  stream.avail_out = (uLong) len;

  while (stream.avail_out != 0)
    {

      if (transparent)
        {
          /* Copy first the lookahead bytes: */
          ssize_t n = stream.avail_in;
          if (n > (ssize_t) stream.avail_out)
            n = stream.avail_out;
          if (n > 0)
            {
              memcpy (stream.next_out, stream.next_in, n);
              next_out += n;
              stream.next_out = next_out;
              stream.next_in += n;
              stream.avail_out -= (uLong) n;
              stream.avail_in -= (uLong) n;
            }
          if (stream.avail_out > 0)
            {
              stream.avail_out -= (uLong) original->read (next_out, stream.avail_out);
            }
          len -= stream.avail_out;
          stream.total_in += (uLong) len;
          stream.total_out += (uLong) len;
          if (len == 0)
            z_eof = 1;
          return (int) len;
        }
      if (stream.avail_in == 0 && !z_eof)
        {

          errno = 0;
          stream.avail_in = (uLong) original->read (inbuf, 16384);
          if (stream.avail_in == 0)
            {
              z_eof = 1;
              if (original->error ())
                {
                  z_err = Z_ERRNO;
                  break;
                }
            }
          stream.next_in = inbuf;
        }
      z_err = inflate (&(stream), Z_NO_FLUSH);

      if (z_err == Z_STREAM_END)
        {
          /* Check CRC and original size */
          crc = crc32 (crc, start, (uInt) (stream.next_out - start));
          start = stream.next_out;

          if (getLong () != crc)
            {
              z_err = Z_DATA_ERROR;
            }
          else
            {
              (void) getLong ();
              /* The uncompressed length returned by above getlong() may
               * be different from stream.total_out) in case of
               * concatenated .gz files. Check for such files:
               */
              check_header ();
              if (z_err == Z_OK)
                {
                  uLong total_in = stream.total_in;
                  uLong total_out = stream.total_out;

                  inflateReset (&(stream));
                  stream.total_in = total_in;
                  stream.total_out = total_out;
                  crc = crc32 (0L, Z_NULL, 0);
                }
            }
        }
      if (z_err != Z_OK || z_eof)
        break;
    }
  crc = crc32 (crc, start, (uInt) (stream.next_out - start));

  return (int) (len - stream.avail_out);
}


/* ===========================================================================
   Writes the given number of uncompressed bytes into the compressed file.
   gzwrite returns the number of bytes actually written (0 in case of error).
*/
ssize_t
compress_gz::write (const void *buffer, size_t len)
{
  if (mode != 'w')
    {
      z_err = Z_STREAM_ERROR;
      return -1;
    }

  stream.next_in = (Bytef *) buffer;
  stream.avail_in = (uLong) len;

  while (stream.avail_in != 0)
    {

      if (stream.avail_out == 0)
        {

          stream.next_out = outbuf;
          if (original->write (outbuf, 16384) != 16384)
            {
              z_err = Z_ERRNO;
              break;
            }
          stream.avail_out = 16384;
        }
      z_err = deflate (&(stream), Z_NO_FLUSH);
      if (z_err != Z_OK)
        break;
    }
  crc = crc32 (crc, (const Bytef *) buffer, (uInt) len);

  return (int) (len - stream.avail_in);
}

ssize_t
compress_gz::peek (void *buffer, size_t len)
{
  if (mode != 'r')
    {
      z_err = Z_STREAM_ERROR;
      return -1;
    }
  /* can only peek 512 bytes */
  if (len > 512)
    {
      z_err = ENOMEM;
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
}

ssize_t
compress_gz::tell ()
{
  throw new logic_error("compress_gz::tell is not implemented");
}

int
compress_gz::seek (long where, io_stream_seek_t whence)
{
  throw new logic_error("compress_gz::seek is not implemented");
}

int
compress_gz::error ()
{
  if (z_err && z_err != Z_STREAM_END)
    return z_err;
  return 0;
}

int
compress_gz::set_mtime (time_t time)
{
  if (original)
    return original->set_mtime (time);
  return 1;
}

time_t
compress_gz::get_mtime ()
{
  if (original)
      return original->get_mtime ();
  return 0;
}

void
compress_gz::release_original ()
{
  owns_original = false;
}

void
compress_gz::destroy ()
{
  if (msg)
    free (msg);
  if (stream.state != NULL)
    {
      if (mode == 'w')
        {
          z_err = deflateEnd (&(stream));
        }
      else if (mode == 'r')
        {
          z_err = inflateEnd (&(stream));
        }
    }

  if (inbuf)
    free (inbuf);
  if (outbuf)
    free (outbuf);
  if (original)
    delete original;
}

compress_gz::~compress_gz ()
{
  if (mode == 'w')
    {
      z_err = do_flush (Z_FINISH);
      if (z_err != Z_OK)
	{
	  destroy ();
	  return;
	}

      putLong (crc);
      putLong (stream.total_in);
    }
  destroy ();
}

int
compress_gz::do_flush (int flush)
{
  ssize_t len;
  int done = 0;
  if (mode != 'w')
    return Z_STREAM_ERROR;
  stream.avail_in = 0;		/* should be zero already anyway */
  for (;;)
    {
      len = 16384 - stream.avail_out;
      if (len != 0)
        {
          if ( original->write (outbuf, len) != len)
            {
              z_err = Z_ERRNO;
              return Z_ERRNO;
            }
          stream.next_out = outbuf;
          stream.avail_out = 16384;
        }
      if (done)
        break;
      z_err = deflate (&(stream), flush);
      /* Ignore the second of two consecutive flushes: */
      if (len == 0 && z_err == Z_BUF_ERROR)
        z_err = Z_OK;
      /* deflate has finished flushing only when it hasn't used up
       * all the available space in the output buffer:
       */
      done = (stream.avail_out != 0 || z_err == Z_STREAM_END);
      if (z_err != Z_OK && z_err != Z_STREAM_END)
        break;
    }
  return z_err == Z_STREAM_END ? Z_OK : z_err;
}


#if 0

gzclose (lst);
#endif
/* ===========================================================================
 *  Read a byte from a gz_stream; update next_in and avail_in. Return EOF
 *  for end of file.
 *  IN assertion: the stream s has been sucessfully opened for reading.
 */
int
compress_gz::get_byte ()
{
  if (z_eof)
    return EOF;
  if (stream.avail_in == 0)
    {
      errno = 0;
      stream.avail_in = (uLong) original->read (inbuf, 16384);
      if (stream.avail_in == 0)
        {
          z_eof = 1;
          if (original->error ())
            z_err = Z_ERRNO;
          return EOF;
        }
      stream.next_in = inbuf;
    }
  stream.avail_in--;
  return *(stream.next_in)++;
}


/* ===========================================================================
      Check the gzip header of a gz_stream opened for reading. Set the stream
    mode to transparent if the gzip magic header is not present; set s->err
    to Z_DATA_ERROR if the magic header is present but the rest of the header
    is incorrect.
    IN assertion: the stream s has already been created sucessfully;
       s->stream.avail_in is zero for the first time, but may be non-zero
       for concatenated .gz files.
*/
void
compress_gz::check_header ()
{
  int method;			/* method byte */
  int flags;			/* flags byte */
  uInt len;
  int c;
  /* Check the gzip magic header */
  for (len = 0; len < 2; len++)
    {
      c = get_byte ();
      if (c != gz_magic[len])
        {
          if (len != 0)
            stream.avail_in++, stream.next_in--;
          if (c != EOF)
            {
              stream.avail_in++, stream.next_in--;
              transparent = 1;
            }
          z_err = stream.avail_in != 0 ? Z_OK : Z_STREAM_END;
          return;
        }
    }
  method = get_byte ();
  flags = get_byte ();
  if (method != Z_DEFLATED || (flags & RESERVED) != 0)
    {
      z_err = Z_DATA_ERROR;
      return;
    }

  /* Discard time, xflags and OS code: */
  for (len = 0; len < 6; len++)
    (void) get_byte ();
  if ((flags & EXTRA_FIELD) != 0)
    {				/* skip the extra field */
      len = (uInt) get_byte ();
      len += ((uInt) get_byte ()) << 8;
      /* len is garbage if EOF but the loop below will quit anyway */
      while (len-- != 0 && get_byte () != EOF);
    }
  if ((flags & ORIG_NAME) != 0)
    {				/* skip the original file name */
      while ((c = get_byte ()) != 0 && c != EOF);
    }
  if ((flags & COMMENT) != 0)
    {				/* skip the .gz file comment */
      while ((c = get_byte ()) != 0 && c != EOF);
    }
  if ((flags & HEAD_CRC) != 0)
    {				/* skip the header crc */
      for (len = 0; len < 2; len++)
        (void) get_byte ();
    }
  z_err = z_eof ? Z_DATA_ERROR : Z_OK;
}
