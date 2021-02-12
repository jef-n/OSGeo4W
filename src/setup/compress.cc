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

#include "compress.h"
#include "compress_gz.h"
#include "compress_bz.h"
#include <string.h>

/* In case you are wondering why the file magic is not in one place:
 * It could be. But there is little (any?) benefit.
 * What is important is that the file magic required for any _task_ is centralised.
 * One such task is identifying compresss
 *
 * to federate into each class one might add a magic parameter to the constructor, which
 * the class could test itself. 
 */

#define longest_magic 3

io_stream *
compress::decompress (io_stream * original)
{
  if (!original)
    return NULL;
  char magic[longest_magic];
  if (original->peek (magic, longest_magic) > 0)
    {
      if (memcmp (magic, "\037\213", 2) == 0)
	{
	  /* tar */
	  compress_gz *rv = new compress_gz (original);
	  if (!rv->error ())
	    return rv;
	  /* else */
	  rv->release_original();
	  delete rv;
	  return NULL;
	}
      else if (memcmp (magic, "BZh", 3) == 0)
	{
	  compress_bz *rv = new compress_bz (original);
	  if (!rv->error ())
	    return rv;
	  /* else */
	  rv->release_original();
	  delete rv;
	  return NULL;
	}
    }
  return NULL;
}

compress::~compress () {}
