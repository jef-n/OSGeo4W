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

#ifndef SETUP_COMPRESS_H
#define SETUP_COMPRESS_H

#include "io_stream.h"

class compress:public io_stream
{
public:
  /* Get a decompressed stream from a normal stream. If this function returns non-null
   * a valid compress header was found. The io_stream pointer passed to decompress
   * should be discarded. The old io_stream will be automatically closed when the
   * decompression stream is closed
   */
  static io_stream *decompress (io_stream *);
  /*
   * To create a stream that will be compressed, you should open the url, and then get a new stream
   * from compress::compress.
   */
  /* read data (duh!) */
  virtual ssize_t read (void *buffer, size_t len) = 0;
  /* provide data to (double duh!) */
  virtual ssize_t write (const void *buffer, size_t len) = 0;
  /* read data without removing it from the class's internal buffer */
  virtual ssize_t peek (void *buffer, size_t len) = 0;
  virtual ssize_t tell () = 0;
  /* try guessing this one */
  virtual int error () = 0;
  /* Find out the next stream name -
   * ie for foo.tar.gz, at offset 0, next_file_name = foo.tar
   * for foobar that is an compress, next_file_name is the next
   * extractable filename.
   */
  virtual const char *next_file_name () = 0;
  /* if you are still needing these hints... give up now! */
  virtual ~compress () = 0;
};

#endif /* SETUP_COMPRESS_H */
