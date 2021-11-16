/*
 * Copyright (c) 2000, 2001, Red Hat, Inc.
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

#ifndef SETUP_STATE_H
#define SETUP_STATE_H

/* The purpose of this file is to contain all the global variables
   that define the "state" of the install, that is, all the
   information that the user has provided so far.  These are set by
   the various dialogs and used by the various actions.

   Note that this is deprecated. Persistent settings should be accessed
   via a class that stores them cross-installs, and non-persistent settings
   directly via the appropriate class. One of the reasons for this is that
   non-trivial types would require this file to include appropriate headers,
   making all of setup.exe rebuild for potentially minor changes.

 */

#include <string>
#include "license.h"

enum attend_mode { attended = 0, unattended, chooseronly };
extern enum attend_mode unattended_mode;
extern bool rebootneeded;

extern bool test_mode;
extern bool safe_mode;

extern int splash_mode;
extern int source;

extern std::string local_dir;
extern std::string menu_name;

extern int root_scope;
extern int root_menu;
extern int root_desktop;

#endif /* SETUP_STATE_H */
