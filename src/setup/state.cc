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

/* All we do here is instantiate the extern'd variables from state.h */

#if 0
static const char *cvsid =
  "\n%%% $Id: state.cc,v 2.7 2010/02/15 00:45:01 davek Exp $\n";
#endif

#include "state.h"
#include "resource.h"

enum attend_mode unattended_mode = attended;
bool rebootneeded;
bool test_mode;
bool safe_mode;

int splash_mode = IDC_ADVANCED;
int source;

std::string local_dir;
std::string menu_name;

int root_scope = 0;
int root_menu = 1;
int root_desktop = 0;
