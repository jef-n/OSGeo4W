/*
 * Copyright (c) 2002, Robert Collins.
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
 * Rewritten by Robert Collins <rbtcollins@hotmail.com>
 *
 */

/* The purpose of this file is to doa recursive find on a given
   directory, calling a given function for each file found. */

#if 0
static const char *cvsid =
  "\n%%% $Id: find.cc,v 2.12 2013/07/03 19:31:11 corinna Exp $\n";
#endif

#include "find.h"

#include "FindVisitor.h"
#include <stdexcept>

using namespace std;

Find::Find(const std::string& starting_dir)
  : h(INVALID_HANDLE_VALUE)
{
  _start_dir = starting_dir;
  size_t l = _start_dir.size ();
  
  /* Ensure that _start_dir has a trailing slash if it doesn't already.  */
  if (l < 1 || (starting_dir[l - 1] != '/' && starting_dir[l - 1] != '\\'))
    _start_dir += '/';
}

Find::~Find()
{
  if (h != INVALID_HANDLE_VALUE && h)
    FindClose (h);
}

void
Find::accept (FindVisitor &aVisitor, int level)
{
  WIN32_FIND_DATA wfd;
  if (_start_dir.size() > MAX_PATH)
    throw new length_error ("starting dir longer than MAX_PATH");

  h = FindFirstFile ((_start_dir + "*").c_str(), &wfd);

  if (h == INVALID_HANDLE_VALUE)
    return;

  do
    {
      if (strcmp (wfd.cFileName, ".") == 0
	  || strcmp (wfd.cFileName, "..") == 0)
	continue;

      /* TODO: make a non-win32 file and dir info class and have that as the 
       * visited node 
       */
      if (wfd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
	aVisitor.visitDirectory (_start_dir, &wfd, level);
      else
	aVisitor.visitFile (_start_dir, &wfd);
    }
  while (FindNextFile (h, &wfd));
}
