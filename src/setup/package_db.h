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

#ifndef SETUP_PACKAGE_DB_H
#define SETUP_PACKAGE_DB_H

/* required to parse this file */
#include <vector>
#include <map>
#include "String++.h"
class packagemeta;
class io_stream;
class PackageSpecification;
class RestrictivePackage;

typedef enum {
  PackageDB_Install,
  PackageDB_Download
} PackageDBActions;

class packagedb;
typedef std::vector <packagemeta *>::iterator PackageDBConnectedIterator;

/*TODO: add mutexes */

/*TODO: add sanity.   Beware, Here Be C++ Dragons:

   This class is a hidden singleton.  It's a singleton, but you create
   and delete transient objects of the class, none of which have any
   member data, but solely serve as shortcuts to access one static set
   of shared data through an irrelevant this-pointer.

   Not only that, but it's a hidden singleton that is constructed
   the first time you access it, and constructed differently
   based on implicit global state.

   Not only that, but it has some static state of its own that also
   controls how it gets constructed, but that could then be changed
   afterward without invalidating the cached data, silently changing
   its semantic interpretation.

   To use this class, you must first set the packagedb::task member
   and the cygfile:// (install dir) root path.  You must only then
   construct a packagedb, and must remember not to change the
   task or root path any later in the execution sequence.

*/

#include <PackageTrust.h>

class packagedb
{
public:
  packagedb ();
  /* 0 on success */
  int flush ();
  packagemeta * findBinary (PackageSpecification const &) const;
  packagemeta * findSource (PackageSpecification const &) const;
  PackageDBConnectedIterator connectedBegin();
  PackageDBConnectedIterator connectedEnd();
  void fillMissingCategory();
  void defaultTrust (trusts trust);
  void markUnVisited();
  void setExistence();
  typedef std::map <std::string, packagemeta *> packagecollection;
  /* all seen binary packages */
  static packagecollection packages;
  /* all seen source packages */
  static packagecollection sourcePackages;
  /* all restrictivly licensed packages by license */
  static std::multimap <std::string, RestrictivePackage *> blacklist;
  /* all seen categories */
  typedef std::map <std::string, std::vector <packagemeta *>, casecompare_lt_op > categoriesType;
  static categoriesType categories;
  static PackageDBActions task;
private:
  static int installeddbread;	/* do we have to reread this */
  friend class ConnectedLoopFinder;
  static std::vector <packagemeta *> dependencyOrderedPackages;
};

#endif /* SETUP_PACKAGE_DB_H */
