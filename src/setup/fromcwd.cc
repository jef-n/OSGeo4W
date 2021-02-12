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

/* The purpose of this file is to handle the case where we're
   installing from files that already exist in the current directory.
   If a setup.ini file is present, we set the mirror site to "." and
   pretend we're installing from the `internet' ;-) else we have to
   find all the .tar.gz files, deduce their versions, and try to
   compare versions in the case where the current directory contains
   multiple versions of any given package.  We do *not* try to compare
   versions with already installed packages; we always choose a
   package in the current directory over one that's already installed
   (otherwise, why would you have asked to install it?).  Note
   that we search recursively. */

#if 0
static const char *cvsid =
  "\n%%% $Id: fromcwd.cc,v 2.35 2013/07/22 05:46:26 cgf Exp $\n";
#endif

#include "win32.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "resource.h"
#include "state.h"
#include "dialog.h"
#include "msg.h"
#include "find.h"
#include "ScanFindVisitor.h"
#include "filemanip.h"
#include "ini.h"

#include "IniDBBuilderPackage.h"
#include "IniParseFeedback.h"

/* Trivial class for detecting the existence of setup.ini */

class SetupFindVisitor : public FindVisitor
{
public:
  SetupFindVisitor (): found(false){}
  virtual void visitFile(const std::string& basePath,
                         const WIN32_FIND_DATA *theFile)
    {
      if (!casecompare (SETUP_INI_FILENAME, theFile->cFileName) && 
	  (theFile->nFileSizeLow || theFile->nFileSizeHigh))
	{
	  /* Check if base dir ends in SETUP_INI_DIR. */
	  const char *dir = basePath.c_str() + basePath.size ()
			    - strlen (SETUP_INI_DIR);
	  if (dir < basePath.c_str ())
	    return;
	  if ((dir != basePath.c_str () && dir[-1] != '/' && dir[-1] != '\\')
	      || casecompare (SETUP_INI_DIR, dir))
	    return;
	  found = true;
	}
    }
  virtual ~ SetupFindVisitor (){}
  operator bool () const {return found;}
protected:
  SetupFindVisitor (SetupFindVisitor const &);
  SetupFindVisitor & operator= (SetupFindVisitor const &);
private:
  bool found;
};
  
bool
do_fromcwd (HINSTANCE h, HWND owner)
{
  // Assume we won't find the INI file.
  SetupFindVisitor found_ini;
  Find(".").accept(found_ini, 2);	// Only search two levels deep.
  if (found_ini)
    {
      // Found INI, load it.
      return true;
    }

  IniParseFeedback myFeedback;
  IniDBBuilderPackage myBuilder(myFeedback);
  ScanFindVisitor myVisitor (myBuilder);
  Find(".").accept(myVisitor);
  return false;
}
