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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>

#include "io_stream.h"
#include "io_stream_memory.h"

/* memblock helper class */
memblock::~memblock ()
{
  if (data)
    delete[] data;
  if (next)
    delete next;
}

io_stream_memory::~io_stream_memory ()
{
  /* memblocks are self deleting. Nice of 'em eh what */
}

/* virtuals */


ssize_t
io_stream_memory::read (void *buffer, size_t len)
{
  if (len == 0)
    return 0;
  unsigned char *to = (unsigned char *) buffer;
  unsigned char *end = to + len;
  ssize_t count = 0;
  while (to < end && pos < length)
    {
      *to++ = pos_block->data[pos_block_offset++];
      count++;
      if (pos_block_offset == pos_block->len)
	{
	  pos_block = pos_block->next;
	  pos_block_offset = 0;
	}
      pos++;
    }
  return count;
}

ssize_t
io_stream_memory::write (const void *buffer, size_t len)
{
  if (len == 0)
    return 0;
  /* talk about primitive :} */
  tail->next = new memblock (len);
  if (!tail->next->data)
    {
      delete tail->next;
      tail->next = 0;
      lasterr = ENOMEM;
      return -1;
    }
  tail = tail->next;
  memcpy (tail->data, buffer, len);
  pos += len;
  pos_block = tail;
  pos_block_offset = len;
  length += len;
  return len;
}

ssize_t
io_stream_memory::peek (void *buffer, size_t len)
{
  size_t tpos = pos;
  size_t toff = pos_block_offset;
  memblock *tblock = pos_block;
  ssize_t tmp = read (buffer, len);
  pos = tpos;
  pos_block_offset = toff;
  pos_block = tblock;
  return tmp;
}

int
io_stream_memory::error ()
{
  return lasterr;
}
