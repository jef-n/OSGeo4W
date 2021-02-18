/*
 * Copyright (c) 2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009,
 * 2010, 2013 Red Hat, Inc.
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

/* The purpose of this file is to hide all the details about accessing
   Cygwin's mount table.  If the format or location of the mount table
   changes, this is the file to change to match it. */

#if 0
static const char *cvsid = "\n%%% $Id: mount.cc,v 2.38 2013/06/30 22:26:41 cgf Exp $\n";
#endif

#include "win32.h"

#include <stdio.h>
#include <stdlib.h>
#include <vector>

#include "state.h"
#include "mount.h"
#include "msg.h"

/*
 * is_elevated () determines whether the process is running elevated
 */

int
is_elevated ()
{
  // Get the process token for the current process
  HANDLE token;
  if (!OpenProcessToken (GetCurrentProcess (), TOKEN_QUERY, &token))
    return 0;

  DWORD size;
  TOKEN_ELEVATION tokenElevation;
  DWORD status = GetTokenInformation (token, TokenElevation, &tokenElevation, sizeof tokenElevation, &size);
  CloseHandle (token);
  if (!status)
    return 0;

  return tokenElevation.TokenIsElevated != 0;
}


static std::string osgeo4w_root;

void
set_root_dir (const std::string val)
{
  if ( osgeo4w_root.empty() )
    msg( "Setting root to %s\n", val.c_str() );
  else if( val != osgeo4w_root )
	msg( "Switching root from %s to %s\n", osgeo4w_root.c_str(), val.c_str() );
  else
    return;

  osgeo4w_root = val;
}

const std::string
get_root_dir ()
{
  if( osgeo4w_root.empty() )
    msg( "Warning root not set yet\n" );
  return osgeo4w_root;
}

std::string
cygpath (const std::string& thePath)
{
   std::string path = get_root_dir() + "/" + thePath;
   // msg( "cygpath(%s) => %s\n", thePath.c_str(), path.c_str() );
   return path;
}
