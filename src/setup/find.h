/*
 * Copyright (c) 2002 Robert Collins.
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
 * Written by Robert Collins <rbtcollins@hotmail.com>
 *
 */

#ifndef SETUP_FIND_H
#define SETUP_FIND_H

#include <string>

class FindVisitor;

/* TODO: make h conditional on the target platform */
#include "win32.h"
#include <climits>

/* An aggregate representing all the files and folders in a given directory */
class Find
{
public:
  Find (const std::string& starting_dir);
  ~Find ();
  void accept (FindVisitor &, int level = INT_MAX);
private:
  std::string _start_dir;
  HANDLE h;
};

#endif /* SETUP_FIND_H */
