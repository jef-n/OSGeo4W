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
 * Written by Robert Collins <robertc@hotmail.com>
 *
 */

#if 0
static const char *cvsid =
  "\n%%% $Id: ScanFindVisitor.cc,v 2.5 2013/07/12 20:23:07 cgf Exp $\n";
#endif

#include "ScanFindVisitor.h"
#include "filemanip.h"
#include "IniDBBuilder.h"

ScanFindVisitor::ScanFindVisitor(IniDBBuilder &aBuilder) : _Builder (aBuilder) {}
ScanFindVisitor::~ScanFindVisitor(){}

/* look for potential packages we can add to the in-memory package
 * database
 */
void
ScanFindVisitor::visitFile(const std::string& basePath,
                           const WIN32_FIND_DATA *theFile)
{
  // Sanity check: Does the file look like a package ?
  fileparse f;
  if (!parse_filename (theFile->cFileName, f))
    return;

  // Sanity check: Zero length package files get thrown out.
  if (!(theFile->nFileSizeLow || theFile->nFileSizeHigh))
    return;

  // Build a new package called f.pkg
  _Builder.buildPackage (f.pkg);

  // Set the version we are bulding
  _Builder.buildPackageVersion (f.ver);

  // Add the file as a installable package
  if (!f.what.size())
    {
      //assume binary
      _Builder.buildPackageInstall (basePath + theFile->cFileName);
      _Builder.buildInstallSize(stringify(theFile->nFileSizeLow));
    }
  else
    // patch or src, assume src until someone complains
    _Builder.buildPackageSource (basePath + theFile->cFileName,
                                 stringify(theFile->nFileSizeLow));

}
