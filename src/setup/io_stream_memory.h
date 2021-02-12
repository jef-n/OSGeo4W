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

#ifndef SETUP_IO_STREAM_MEMORY_H
#define SETUP_IO_STREAM_MEMORY_H

/* needed to parse */
#include <errno.h>

/* this is a stream class that simply abstracts the issue of maintaining
 * amemory buffer.
 * It's not as efficient as if can be, but that can be fixed without affecting 
 * the API. 
 */

class memblock
{
public:
  memblock () : next (0), len (0), data (0) {};
  memblock (size_t size) : next (0), len (size) {data = new unsigned char[size]; if (!data) len = 0;};
  ~memblock ();
  memblock *next;
  size_t len;
  unsigned char *data;
};

class io_stream_memory :public io_stream
{
public:
  io_stream_memory () : lasterr (0), mtime(0),length (0), head(), tail (&head), pos_block (head.next), pos_block_offset (0), pos (0) {}

  /* set the modification time of a file - returns 1 on failure
   * may disrupt internal state - use after all important io is complete
   */
  virtual int set_mtime (time_t newmtime) {mtime = newmtime;return 0;}
  /* get the mtime for a file TODO make this a stat(0 style call */
  virtual time_t get_mtime () {return mtime;};
  /* returns the _current_ size. */
  virtual size_t get_size () {return length;};
  /* read data (duh!) */
  virtual ssize_t read (void *buffer, size_t len);
  /* provide data to (double duh!) */
  virtual ssize_t write (const void *buffer, size_t len);
  /* read data without removing it from the class's internal buffer */
  virtual ssize_t peek (void *buffer, size_t len);
  /* ever read the f* functions from libc ? */
  virtual ssize_t tell () {return pos;}
  virtual int seek (long where, io_stream_seek_t whence)
  {
    if (whence != IO_SEEK_SET)
      {
	lasterr = EINVAL;
	return -1;
      }

    long count = 0;
    pos = 0;
    pos_block = head.next;
    pos_block_offset = 0;
    while (count < where && pos < length)
      {
	pos_block_offset++;
	if (pos_block_offset == pos_block->len)
	  {
	    pos_block = pos_block->next;
	    pos_block_offset = 0;
	  }

	pos++;
	count++;
      }

    return 0;
  }
    
  /* try guessing this one */
  virtual int error ();
//  virtual const char* next_file_name() = NULL;
  /* if you are still needing these hints... give up now! */
  virtual ~ io_stream_memory ();
private:
  int lasterr;
  time_t mtime;
  size_t length;
  memblock head;
  memblock *tail;
  memblock *pos_block;
  size_t pos_block_offset;
  size_t pos;
};

#endif /* SETUP_IO_STREAM_MEMORY_H */
