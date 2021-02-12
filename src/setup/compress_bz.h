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

#ifndef SETUP_COMPRESS_BZ_H
#define SETUP_COMPRESS_BZ_H

#include "compress.h"

#include <bzlib.h>

class compress_bz:public compress
{
public:
  /* assumes decompression */
  compress_bz (io_stream *);
  /* allows comp/decomp but this implementation only handles comp */
  compress_bz (io_stream *, const char *);
  /* read data (duh!) */
  virtual ssize_t read (void *buffer, size_t len);
  /* provide data to (double duh!) */
  virtual ssize_t write (const void *buffer, size_t len);
  /* read data without removing it from the class's internal buffer */
  virtual ssize_t peek (void *buffer, size_t len);
  virtual ssize_t tell ();
  virtual int seek (long where, io_stream_seek_t whence);
  /* try guessing this one */
  virtual int error ();
  /* Find out the next stream name -
   * ie for foo.tar.bz, at offset 0, next_file_name = foo.tar
   * for foobar that is an compress, next_file_name is the next
   * extractable filename.
   */
  virtual const char *next_file_name () { return NULL; }
  virtual int set_mtime (time_t);
  /* Use seek EOF, then tell (). get_size won't do this incase you are sucking dow
      * over a WAN :} */
  virtual size_t get_size () {return 0;}
  virtual time_t get_mtime ();
  virtual void release_original (); /* give up ownership of original io_stream */
  /* if you are still needing these hints... give up now! */
    virtual ~ compress_bz ();
private:
  io_stream *original;
  bool owns_original;
  char peekbuf[512];
  size_t peeklen;
  ssize_t lasterr;
  bz_stream strm;
  int initialisedOk;
  int endReached;
  char buf[4096];
  int writing;
  size_t position;
};

#endif /* SETUP_COMPRESS_BZ_H */
