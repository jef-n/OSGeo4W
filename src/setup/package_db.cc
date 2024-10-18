/*
 * Copyright (c) 2001, 2003 Robert Collins.
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

/* this is the package database class.
 * It lists all known packages, including custom ones, ones from a mirror and
 * installed ones.
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#ifdef HAVE_STRINGS_H
#include <strings.h>
#endif
#include <algorithm>
#if HAVE_ERRNO_H
#include <errno.h>
#endif

#include "io_stream.h"
#include "compress.h"

#include "filemanip.h"

#include "package_version.h"
#include "cygpackage.h"
#include "package_db.h"
#include "package_meta.h"
#include "Exception.h"
#include "Generic.h"

using namespace std;

packagedb::packagedb ()
{
  io_stream *db = 0;
  if (!installeddbread)
    {
      /* no parameters. Read in the local installation database. */
      db = io_stream::open ("cygfile:///etc/setup/installed.db", "rt");
      installeddbread = 1;
      if (!db)
	return;
      /* flush_local_db_package_data */
      char line[1000], pkgname[1000], inst[1000];
      int instsz;

      if (db->gets (line, 1000))
	{
	  int dbver;
	  sscanf (line, "%s %d", pkgname, &instsz);
	  if (!strcasecmp (pkgname, "INSTALLED.DB") && instsz == 2)
	    dbver = 2;
	  else
	    dbver = 1;
	  delete db;
	  db = 0;
	  /* Later versions may not use installed.db other than to record the version. */
	  if (dbver == 1 || dbver == 2)
	    {
	      db =
		io_stream::open ("cygfile:///etc/setup/installed.db", "rt");
	      if (dbver == 2)
		db->gets (line, 1000);
	      while (db->gets (line, 1000))
		{
		  int parseable;
		  int ign;
		  pkgname[0] = '\0';
		  inst[0] = '\0';

		  sscanf (line, "%s %s %d", pkgname, inst, &ign);

		  if (pkgname[0] == '\0' || inst[0] == '\0')
			continue;

		  fileparse f;
		  parseable = parse_filename (inst, f);
		  if (!parseable)
		    continue;

		  packagemeta *pkg = findBinary (PackageSpecification(pkgname));
		  if (!pkg)
		    {
		      pkg = new packagemeta (pkgname, inst);
		      packages.insert (packagedb::packagecollection::value_type(pkgname, pkg));
		      /* we should install a new handler then not check this...
		       */
		      //if (!pkg)
		      //die badly
		    }

		  packageversion binary =
		    cygpackage::createInstance (pkgname, inst, f.ver,
	    					package_installed,
	    					package_binary);

		  pkg->add_version (binary);
		  pkg->set_installed (binary);
		  pkg->desired = pkg->installed;
		}
	      delete db;
	      db = 0;
	    }
	  else
	    // unknown dbversion
	    exit (1);
	}
    }
}

int
packagedb::flush ()
{
  /* naive approach - just dump the lot */
  char const *odbn = "cygfile:///etc/setup/installed.db";
  char const *ndbn = "cygfile:///etc/setup/installed.db.new";

  io_stream::mkpath_p (PATH_TO_FILE, ndbn);

  io_stream *ndb = io_stream::open (ndbn, "wb");

  // XXX if this failed, try removing any existing .new database?
  if (!ndb)
    return errno ? errno : 1;

  ndb->write ("INSTALLED.DB 2\n", strlen ("INSTALLED.DB 2\n"));
  for (packagedb::packagecollection::iterator i = packages.begin ();
       i != packages.end (); ++i)
    {
      packagemeta & pkgm = *(i->second);
      if (pkgm.installed)
	{
	  /* size here is irrelevant - as we can assume that this install source
	   * no longer exists, and it does not correlate to used disk space
	   * also note that we are writing a fictional install source
	   * to keep cygcheck happy.
	   */
	  std::string line;
	  line = pkgm.name + " " + pkgm.name + "-" +
	    std::string(pkgm.installed.Canonical_version()) + ".tar.bz2 0\n";
	  ndb->write (line.c_str(), line.size());
	}
    }

  delete ndb;

  io_stream::remove (odbn);

  if (io_stream::move (ndbn, odbn))
    return errno ? errno : 1;
  return 0;
}

packagemeta *
packagedb::findBinary (PackageSpecification const &spec) const
{
  packagedb::packagecollection::iterator n = packages.find(spec.packageName());
  if (n != packages.end())
    {
      packagemeta & pkgm = *(n->second);
      for (set<packageversion>::iterator i=pkgm.versions.begin();
	  i != pkgm.versions.end(); ++i)
	if (spec.satisfies (*i))
	  return &pkgm;
    }
  return NULL;
}

packagemeta *
packagedb::findSource (PackageSpecification const &spec) const
{
  packagedb::packagecollection::iterator n = sourcePackages.find(spec.packageName());
  if (n != sourcePackages.end())
    {
      packagemeta & pkgm = *(n->second);
      for (set<packageversion>::iterator i = pkgm.versions.begin();
	   i != pkgm.versions.end(); ++i)
	if (spec.satisfies (*i))
	  return &pkgm;
    }
  return NULL;
}

/* static members */

int packagedb::installeddbread = 0;
packagedb::packagecollection packagedb::packages;
packagedb::categoriesType packagedb::categories;
packagedb::packagecollection packagedb::sourcePackages;
PackageDBActions packagedb::task = PackageDB_Install;
std::vector <packagemeta *> packagedb::dependencyOrderedPackages;
std::multimap <std::string, RestrictivePackage *> packagedb::blacklist;


#include "LogSingleton.h"
#include <stack>

class
ConnectedLoopFinder
{
public:
  ConnectedLoopFinder(void);
  void doIt(void);
private:
  size_t visit (packagemeta *pkg);

  packagedb db;
  size_t visited;

  typedef std::map<packagemeta *, size_t> visitMap;
  visitMap visitOrder;
  std::stack<packagemeta *> nodesInStronglyConnectedComponent;
};

ConnectedLoopFinder::ConnectedLoopFinder() : visited(0)
{
  for (packagedb::packagecollection::iterator i = db.packages.begin ();
       i != db.packages.end (); ++i)
    visitOrder.insert(visitMap::value_type(i->second, 0));
}

void
ConnectedLoopFinder::doIt()
{
  /* XXX this could be done using a class to hold both the visitedInIteration and the package
   * meta reference. Then we could use a range, not an int loop.
   */
  /* We have to expect dependency loops.  These loops break the topological
     sorting which would be a result of the below algorithm looking for
     strongly connected components in a directed graph.  Unfortunately it's
     not possible to order a directed graph with loops topologially.
     So we always have to make sure that the really important packages don't
     introduce dependency loops, since we can't do this from within setup. */
  for (packagedb::packagecollection::iterator i = db.packages.begin ();
       i != db.packages.end (); ++i)
    {
      packagemeta &pkg (*(i->second));
      if (pkg.installed && !visitOrder[&pkg])
	visit (&pkg);
    }
  log (LOG_BABBLE) << "Visited: " << visited << " nodes out of "
                   << db.packages.size() << " while creating dependency order."
                   << endLog;
}

static bool
checkForInstalled (PackageSpecification *spec)
{
  packagedb db;
  packagemeta *required = db.findBinary (*spec);
  if (!required)
    return false;
  if (spec->satisfies (required->installed)
      && required->desired == required->installed )
    /* done, found a satisfactory installed version that will remain
       installed */
    return true;
  return false;
}

size_t
ConnectedLoopFinder::visit(packagemeta *nodeToVisit)
{
  if (!nodeToVisit->installed)
    /* Can't visit this node, and it is not less than any visited node */
    return db.packages.size() + 1;

  if (visitOrder[nodeToVisit])
    return visitOrder[nodeToVisit];

  ++visited;
  visitOrder[nodeToVisit] = visited;

#if DEBUG
  log (LOG_PLAIN) << "visited '" << nodeToVisit->name << "', assigned id " << visited << endLog;
#endif

  size_t minimumVisitId = visited;
  nodesInStronglyConnectedComponent.push(nodeToVisit);

  vector <vector <PackageSpecification *> *>::const_iterator dp = nodeToVisit->installed.depends()->begin();
  /* walk through each and clause (a link in the graph) */
  while (dp != nodeToVisit->installed.depends()->end())
    {
      /* check each or clause for an installed match */
      vector <PackageSpecification *>::const_iterator i = find_if ((*dp)->begin(), (*dp)->end(), checkForInstalled);
      if (i != (*dp)->end())
	{
	  /* we found an installed ok package */
	  /* visit it if needed */
	  /* UGLY. Need to refactor. iterators in the outer would help as we could simply
	   * visit the iterator
	   */
	  const packagedb::packagecollection::iterator n = db.packages.find((*i)->packageName());

	  if (n == db.packages.end())
	     log (LOG_PLAIN) << "Search for package '" << (*i)->packageName() << "' failed." << endLog;
	   else
	   {
	       packagemeta *nodeJustVisited = n->second;
	       minimumVisitId = std::min (minimumVisitId, visit (nodeJustVisited));
	   }
	  /* next and clause */
	  ++dp;
	  continue;
	}
	/* not installed or not available we ignore */
      ++dp;
    }

  if (minimumVisitId == visitOrder[nodeToVisit])
  {
    packagemeta *popped;
    do {
      popped = nodesInStronglyConnectedComponent.top();
      nodesInStronglyConnectedComponent.pop();
      db.dependencyOrderedPackages.push_back(popped);
      /* mark as displayed in a connected component */
      visitOrder[popped] = db.packages.size() + 2;
    } while (popped != nodeToVisit);
  }

  return minimumVisitId;
}

PackageDBConnectedIterator
packagedb::connectedBegin()
{
  if (!dependencyOrderedPackages.size())
    {
      ConnectedLoopFinder doMe;
      doMe.doIt();
      std::string s = "Dependency order of packages: ";

      for (std::vector<packagemeta *>::iterator i =
           dependencyOrderedPackages.begin();
           i != dependencyOrderedPackages.end(); ++i)
        s = s + (*i)->name + " ";
      log (LOG_BABBLE) << s << endLog;
    }
  return dependencyOrderedPackages.begin();
}

PackageDBConnectedIterator
packagedb::connectedEnd()
{
  return dependencyOrderedPackages.end();
}

void
packagedb::markUnVisited()
{
  for (packagedb::packagecollection::iterator n = packages.begin ();
       n != packages.end (); ++n)
    {
      packagemeta & pkgm = *(n->second);
      pkgm.visited(false);
    }
}

void
packagedb::setExistence ()
{
  /* binary packages */
  /* Remove packages that are in the db, not installed, and have no
     mirror info and are not cached for both binary and source packages. */
  packagedb::packagecollection::iterator i = packages.begin ();
  while (i != packages.end ())
    {
      packagemeta & pkg = *(i->second);
      if (!pkg.installed && !pkg.accessible() &&
          !pkg.sourceAccessible() )
        {
          packagemeta *pkgm = (*i).second;
          delete pkgm;
          i = packages.erase (i);
        }
      else
        ++i;
    }
}

void
packagedb::fillMissingCategory ()
{
  for (packagedb::packagecollection::iterator i = packages.begin(); i != packages.end(); i++)
    {
      if (i->second->hasNoCategories())
        i->second->setDefaultCategories();

      i->second->addToCategoryAll();
    }
}

void
packagedb::defaultTrust (trusts trust)
{
  for (packagedb::packagecollection::iterator i = packages.begin (); i != packages.end (); ++i)
    {
      packagemeta & pkg = *(i->second);
      if (pkg.installed
            || pkg.categories.find ("Base") != pkg.categories.end ()
            || pkg.categories.find ("Misc") != pkg.categories.end ())
        {
          pkg.desired = pkg.trustp (trust);
          if (pkg.desired)
            pkg.desired.pick (pkg.desired.accessible() && pkg.desired != pkg.installed, &pkg);
        }
      else
        pkg.desired = packageversion ();
    }

  // side effect, remove categories with no packages.
  for (packagedb::categoriesType::iterator n = packagedb::categories.begin();
       n != packagedb::categories.end(); ++n)
    if (!n->second.size())
      {
        log (LOG_BABBLE) << "Removing empty category " << n->first << endLog;
        packagedb::categories.erase (n++);
      }
}
