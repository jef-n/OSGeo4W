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

#ifndef SETUP_PACKAGE_SOURCE_H
#define SETUP_PACKAGE_SOURCE_H

/* this is the parent class for all package source (not source code - installation
 * source as in http/ftp/disk file) operations.
 */

/* required to parse this file */
#ifdef HAVE_STRINGS_H
#include "strings.h"
#endif
#include "String++.h"
#include "csu_util/MD5Sum.h"
#include <vector>

/* standard binary package metadata:
 * Name (ie mutt
 * Vendor Version (ie 2.5.1)
 * Package Version (ie 16)
 * Stability 
 * Files 
 */

/* For non installed files, this class can be populated via information about
 * what is available on the net, or by parsing a specific package file.
 * for installed packages, this class should represent what is currently installed,
 * - updated by what net metadata has about it.
 * i.e. the stability of this version will change simply because the net mirrors
 * now consider it old.
 */

class site
{
public:
  site (const std::string& newkey);
  ~site () {}
  std::string key;
  bool operator == (site const &rhs)
    {
      return casecompare(key, rhs.key) == 0;
    }
};

class packagesource
{
public:
  packagesource ()
    : size (0), canonical (0), base (0), filename (0), cached ()
    , _installedSize (0)
  {}
  /* how big is the source file */
  size_t size;
  /* how much space do we need to install this ? */
  virtual unsigned long installedSize () const
    {
      return _installedSize;
    }
  virtual void setInstalledSize (unsigned long size)
    {
      _installedSize = size;
    }
  /* The canonical name - the complete path to the source file 
   * i.e. foo/bar/package-1.tar.bz2
   */
  virtual const char *Canonical () const
  {
    return canonical;
  }
  /* The basename - without extention 
   * i.e. package-1
   */
  virtual const char *Base () const
  {
    return base;
  }
  /* The basename - with extention 
   * i.e. package-1.tar.bz2
   */
  virtual const char *Filename () const
  {
    return filename;
  }
  /* what is the cached filename, to prevent directory scanning during install */
  virtual char const *Cached () const
  {
    /* Pointer-coerce-to-boolean is used by many callers. */
    if (cached.empty())
      return NULL;
    return cached.c_str();
  }
  /* sets the canonical path, and parses and creates base and filename */
  virtual void set_canonical (char const *);
  virtual void set_cached (const std::string& );
  MD5Sum md5;
  typedef std::vector <site> sitestype;
  sitestype sites;

  virtual ~ packagesource ()
  {
    if (canonical)
      delete []canonical;
    if (base)
      delete []base;
    if (filename)
      delete []filename;
  }

private:
  char *canonical;
  char *base;
  char *filename;
  std::string cached;
  unsigned long _installedSize;
};

#endif /* SETUP_PACKAGE_SOURCE_H */
