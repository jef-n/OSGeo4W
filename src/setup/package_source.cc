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

/* this is the parent class for all package source (not source code - installation
 * source as in http/ftp/disk file) operations.
 */

#include <stdlib.h>
#ifdef HAVE_STRINGS_H
#include <strings.h>
#endif
#include <string.h>
#include "package_source.h"

site::site (const std::string& newkey) : key(newkey)
{
}

void
packagesource::set_canonical (char const *fn)
{
  if (canonical)
    delete[] canonical;
  canonical = new char[strlen (fn) + 1];
  strcpy (canonical, fn);

  /* The base is from the last '/' to the first '.' following the last - */
  char const *bstart = strchr (fn, '/');
  char const *tmp;
  while (bstart && (tmp = strchr (bstart + 1, '/')))
    bstart = tmp;

  if (bstart)
    bstart++;
  else
    bstart = fn;
  char const *bend = strchr (bstart, '-');
  while (bend && (tmp = strchr (bend + 1, '-')))
    bend = tmp;
  if (bend)
    bend = strchr (bend, '.');
  else
    bend = strchr (bstart, '.');

  if (!bend)
    bend = strchr (bstart, '\0');
  char const *end = strchr (fn, '\0');
  if (base)
    delete[] base;
  base = new char[bend - bstart + 1];
  memcpy (base, bstart, bend - bstart);
  base[bend - bstart] = '\0';

  if (filename)
    delete[] filename;
  filename = new char[end - bstart + 1];
  memcpy (filename, bstart, end - bstart);
  filename[end - bstart] = '\0';

  cached = std::string();
}

void
packagesource::set_cached (const std::string& fp)
{
  cached = fp;
}
