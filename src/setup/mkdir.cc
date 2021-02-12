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

/* see mkdir.h */

#if 0
static const char *cvsid =
  "\n%%% $Id: mkdir.cc,v 2.6 2003/01/15 22:29:16 maxb Exp $\n";
#endif

#include "win32.h"
#include <sys/stat.h>
#include <stdio.h>

#include "mkdir.h"
#include "filemanip.h"
#include <vector>

/* Return 0 on success.
   A mode of 0 means no POSIX perms. */
int
mkdir_p (int isadir, const char *path)
{
  char saved_char, *slash = 0;
  char *c;
  DWORD d, gse;

  d = GetFileAttributesA (path);
  if (d != INVALID_FILE_ATTRIBUTES && d & FILE_ATTRIBUTE_DIRECTORY)
    return 0;

  if (isadir)
    {
      if (CreateDirectoryA (path, 0))
        return 0;
      gse = GetLastError ();
      if (gse != ERROR_PATH_NOT_FOUND && gse != ERROR_FILE_NOT_FOUND)
	{
	  if (gse == ERROR_ALREADY_EXISTS)
	    {
	      fprintf (stderr,
		       "warning: deleting \"%s\" so I can make a directory there\n",
		       path);
	      if (DeleteFileA (path))
                return mkdir_p (isadir, path);
	    }
	  return 1;
	}
    }

  for (c = (char *) path; *c; c++)
    {
      if (*c == ':')
	slash = 0;
      if (*c == '/' || *c == '\\')
	slash = c;
    }

  if (!slash)
    return 0;

  // Trying to create a drive... It's time to give up.
  if (((slash - path) == 2) && (path[1] == ':'))
    return 1;

  saved_char = *slash;
  *slash = 0;
  if (mkdir_p (1, path))
    {
      *slash = saved_char;
      return 1;
    }
  
  *slash = saved_char;

  if (!isadir)
    return 0;

  return mkdir_p (isadir, path);
}
