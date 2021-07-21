/*
 * Copyright (c) 2000, Red Hat, Inc.
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
 *
 */

/* The purpose of this file is to hide the mess needed just to figure
   out how full a given disk is.  There is an old API that can't
   handle disks bigger than 2G, and a new API that isn't always
   available. */

#include "win32.h"

#include "diskfull.h"

int
diskfull (const std::string& path)
{
  ULARGE_INTEGER avail, total, free;
  if (GetDiskFreeSpaceEx (path.c_str(), &avail, &total, &free))
    {
      int perc = (int) (avail.QuadPart * 100 / total.QuadPart);
      return 100 - perc;
    }

  char root[4];
  if (path.c_str()[1] != ':')
    return 0;

  root[0] = path.c_str()[0];
  root[1] = ':';
  root[2] = '\\';
  root[3] = 0;

  DWORD junk, free_clusters, total_clusters;

  if (GetDiskFreeSpace (root, &junk, &junk, &free_clusters, &total_clusters))
    {
      int perc = free_clusters * 100 / total_clusters;
      return 100 - perc;
    }

  return 0;
}
