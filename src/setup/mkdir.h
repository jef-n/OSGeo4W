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

#ifndef SETUP_MKDIR_H
#define SETUP_MKDIR_H

/* Create a directory, and any needed parent directories.  If "isadir"
   is non-zero, "path" is the name of a directory.  If "isadir" is
   zero, "path" is the name of a *file* that we need a directory
   for. */

extern int mkdir_p (int isadir, const char *path);

#endif /* SETUP_MKDIR_H */
