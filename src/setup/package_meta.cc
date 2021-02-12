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

#if 0
static const char *cvsid = "\n%%% $Id: package_meta.cc,v 2.63 2013/07/25 12:03:49 corinna Exp $\n";
#endif

#include "package_meta.h"

#include <string>
#include <set>
#include <functional>
using namespace std;

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#ifdef HAVE_STRINGS_H
#include <strings.h>
#endif
#include "getopt++/StringArrayOption.h"

#include "io_stream.h"
#include "compress.h"

#include "filemanip.h"
#include "LogSingleton.h"
/* io_stream needs a bit of tweaking to get rid of this. TODO */
#include "mount.h"
/* this goes at the same time */
#include "win32.h"


#include "script.h"

#include "package_version.h"
#include "cygpackage.h"
#include "package_db.h"

#include <algorithm>
#include "Generic.h"

using namespace std;

static StringArrayOption DeletePackageOption ('x', "remove-packages", "Specify packages to uninstall");
static StringArrayOption DeleteCategoryOption ('c', "remove-categories", "Specify categories to uninstall");
static StringArrayOption PackageOption ('P', "packages", "Specify packages to install");
static StringArrayOption CategoryOption ('C', "categories", "Specify entire categories to install");
bool hasManualSelections = 0;

/*****************/

const packagemeta::_actions packagemeta::Default_action (0);
const packagemeta::_actions packagemeta::Install_action (1);
const packagemeta::_actions packagemeta::Reinstall_action (2);
const packagemeta::_actions packagemeta::Uninstall_action (3);

char const *
packagemeta::_actions::caption ()
{
  switch (_value)
    {
    case 0:
      return "Default";
    case 1:
      return "Install";
    case 2:
      return "Reinstall";
    case 3:
      return "Uninstall";
    }
  // Pacify GCC: (all case options are checked above)
  return 0;
}

packagemeta::packagemeta (packagemeta const &rhs)
  : name (rhs.name), key (rhs.name), installed_from ()
  , categories (rhs.categories), versions (rhs.versions)
  , installed (rhs.installed)
  , prev (rhs.prev)
  , curr (rhs.curr)
  , exp (rhs.exp)
  , desired (rhs.desired)
  , architecture (rhs.architecture), priority (rhs.priority)
  , visited_(rhs.visited_)
{
}

packagemeta::_actions & packagemeta::_actions::operator++ ()
{
  ++_value;
  if (_value > 3)
    _value = 0;
  return *this;
}

template<class T> struct removeCategory : public unary_function<T, void>
{
  removeCategory(packagemeta *pkg) : _pkg (pkg) {}
  void operator() (T x) 
    {
      vector <packagemeta *> &aList = packagedb::categories[x]; 
      aList.erase (find (aList.begin(), aList.end(), _pkg));
    }
  packagemeta *_pkg;
};


packagemeta::~packagemeta()
{
  for_each (categories.begin (), categories.end (), removeCategory<std::string> (this));
  categories.clear ();
  versions.clear ();
}

void
packagemeta::add_version (packageversion & thepkg)
{
  /* todo: check return value */
  versions.insert (thepkg);
}

/* assumption: package thepkg is already in the metadata list. */
void
packagemeta::set_installed (packageversion & thepkg)
{
  set<packageversion>::const_iterator temp = versions.find (thepkg);
  if (temp != versions.end())
    installed = thepkg;
}

/* uninstall a package if it's installed */
void
packagemeta::uninstall ()
{
  if (installed)
    {
      /* this will need to be pushed down to the version, or even the source level
       * to allow differences between formats to be seamlessly managed
       * but for now: here is ok
       */
      set<string> dirs;
      string line = installed.getfirstfile ();

      while (line.size())
        {
          /* Insert the paths of all parent directories of line into dirs. */
          size_t idx = line.length();
          while ((idx = line.find_last_of('/', idx-1)) != string::npos)
          {
            string dir_path = line.substr(0, idx);
            bool was_new = dirs.insert(dir_path).second;
            /* If the path was already present in dirs, then all parent paths
             * must necessarily be present also, so don't do any further work.
             * */
            if (!was_new) break;
          }

          std::string d = cygpath ("/" + line);
          DWORD dw = GetFileAttributesA (d.c_str());
          if (dw != INVALID_FILE_ATTRIBUTES
	      && !(dw & FILE_ATTRIBUTE_DIRECTORY))
            {
	      log (LOG_BABBLE) << "unlink " << d << endLog;
	      SetFileAttributesA (d.c_str(),
	                          dw & ~FILE_ATTRIBUTE_READONLY);
	      DeleteFileA (d.c_str());
	    }
	  /* Check for Windows shortcut of same name. */
	  d += ".lnk";
	  dw = GetFileAttributesA (d.c_str());
	  if (dw != INVALID_FILE_ATTRIBUTES
	      && !(dw & FILE_ATTRIBUTE_DIRECTORY))
	    {
	      log (LOG_BABBLE) << "unlink " << d << endLog;
	      SetFileAttributesA (d.c_str(),
	                          dw & ~FILE_ATTRIBUTE_READONLY);
	      DeleteFileA (d.c_str());
	    }
	  line = installed.getnextfile ();
        }
      installed.uninstall ();

      /* An STL set maintains itself in sorted order. Thus, iterating over it
       * in reverse order will ensure we process directories depth-first. */
      set<string>::const_iterator it = dirs.end();
      while (it != dirs.begin())
      {
        it--;
        std::string d = cygpath("/" + *it);
        if (RemoveDirectoryA (d.c_str()))
          log (LOG_BABBLE) << "rmdir " << d << endLog;
      }
    }
  installed = packageversion();
}


void
packagemeta::add_category (const std::string& cat)
{
  if (categories.find (cat) != categories.end())
    return;
  /* add a new record for the package list */
  packagedb::categories[cat].push_back (this);
  categories.insert (cat);
}

struct StringConcatenator : public unary_function<const std::string, void>{
    StringConcatenator(std::string aString) : gap(aString){}
    void operator()(const std::string& aString) 
    {
      if (result.size() != 0)
        result += gap;
      result += aString;
    }
    std::string result;
    std::string gap;
};

const std::string
packagemeta::getReadableCategoryList () const
{
  return for_each(
    categories.begin(),
    categories.end(),
    visit_if(
      StringConcatenator(", "),
      bind(not_equal_to<std::string>(), "All", placeholders::_1)
    )
  ).visitor.result;
}

static bool
hasSDesc(packageversion const &pkg)
{
  return pkg.SDesc().size() > 0;
}

static void
parseNames (std::set<string> &parsed, std::string &option)
{
  string tname;

  /* Split up the packages listed in the option.  */
  string::size_type loc = option.find (",", 0);
  while (loc != string::npos)
    {
      tname = option.substr (0, loc);
      option = option.substr (loc + 1);
      parsed.insert (tname);
      loc = option.find (",", 0);
    }

  /* At this point, no "," exists in option.  Don't add
     an empty string if the entire option was empty.  */
  if (option.length ())
    parsed.insert (option);
}

bool packagemeta::isManuallyWanted() const
{
  static bool parsed_yet = false;
  static std::set<string> parsed_names;
  hasManualSelections |= parsed_names.size () > 0;
  static std::set<string> parsed_categories;
  hasManualSelections |= parsed_categories.size () > 0;
  bool bReturn = false;

  /* First time through, we parse all the names out from the 
    option string and store them away in an STL set.  */
  if (!parsed_yet)
  {
    vector<string> packages_options = PackageOption;
    vector<string> categories_options = CategoryOption;
    for (vector<string>::iterator n = packages_options.begin ();
		n != packages_options.end (); ++n)
      {
	parseNames (parsed_names, *n);
      }
    for (vector<string>::iterator n = categories_options.begin ();
		n != categories_options.end (); ++n)
      {
	parseNames (parsed_categories, *n);
      }
    parsed_yet = true;
  }

  /* Once we've already parsed the option string, just do
    a lookup in the cache of already-parsed names.  */
  bReturn = parsed_names.find(name) != parsed_names.end();

  /* If we didn't select the package manually, did we select any 
     of the categories it is in? */
  if (!bReturn && parsed_categories.size ())
    {
      std::set<std::string, casecompare_lt_op>::iterator curcat;
      for (curcat = categories.begin (); curcat != categories.end (); curcat++)
	if (parsed_categories.find (*curcat) != parsed_categories.end ())
	  {
	    log (LOG_PLAIN) << "Found category " << *curcat << " in package " << name << endLog;
	    bReturn = true;
	  }
    }
  
  if (bReturn)
    log (LOG_PLAIN) << "Added manual package " << name << endLog;
  return bReturn;
}

bool packagemeta::isManuallyDeleted() const
{
  static bool parsed_yet = false;
  static std::set<string> parsed_delete;
  hasManualSelections |= parsed_delete.size () > 0;
  static std::set<string> parsed_delete_categories;
  hasManualSelections |= parsed_delete_categories.size () > 0;
  bool bReturn = false;

  /* First time through, we parse all the names out from the
    option string and store them away in an STL set.  */
  if (!parsed_yet)
  {
    vector<string> delete_options   = DeletePackageOption;
    vector<string> categories_options = DeleteCategoryOption;
    for (vector<string>::iterator n = delete_options.begin ();
		n != delete_options.end (); ++n)
      {
	parseNames (parsed_delete, *n);
      }
    for (vector<string>::iterator n = categories_options.begin ();
		n != categories_options.end (); ++n)
      {
	parseNames (parsed_delete_categories, *n);
      }
    parsed_yet = true;
  }

  /* Once we've already parsed the option string, just do
    a lookup in the cache of already-parsed names.  */
  bReturn = parsed_delete.find(name) != parsed_delete.end();

  /* If we didn't select the package manually, did we select any
     of the categories it is in? */
  if (!bReturn && parsed_delete_categories.size ())
    {
      std::set<std::string, casecompare_lt_op>::iterator curcat;
      for (curcat = categories.begin (); curcat != categories.end (); curcat++)
	if (parsed_delete_categories.find (*curcat) != parsed_delete_categories.end ())
	  {
	    log (LOG_PLAIN) << "Found category " << *curcat << " in package " << name << endLog;
	    bReturn = true;
	  }
    }

  if (bReturn)
    log (LOG_PLAIN) << "Deleted manual package " << name << endLog;
  return bReturn;
}

const std::string
packagemeta::SDesc () const
{
  set<packageversion>::iterator i = find_if (versions.begin(), versions.end(), hasSDesc);
  if (i == versions.end())
    return std::string();
  return i->SDesc ();
}

/* Return an appropriate caption given the current action. */
std::string 
packagemeta::action_caption () const
{
  if (!desired && installed)
    return "Uninstall";
  else if (!desired)
    return "Skip";
  else if (desired == installed && desired.picked())
    return packagedb::task == PackageDB_Install ? "Reinstall" : "Retrieve";
  else if (desired == installed && desired.sourcePackage() && desired.sourcePackage().picked())
    /* FIXME: Redo source should come up if the tarball is already present locally */
    return "Source";
  else if (desired == installed)	/* and neither src nor bin */
    return "Keep";
  else
    return desired.Canonical_version ();
}

/* Set the next action given a current action.  */
void
packagemeta::set_action (packageversion const &default_version)
{
  /* actions are the following:

     for install modes (from net/local)
     for each version:
     install this version
     install the source for this version
     and a boolean flag - force install to allow reinstallation, or bypassing requirements
     globally:
     install the source for the current version.

     to uninstall a package, the desired version is set to NULL;

     for mirroring modes (download only)
     for each version
     download this version
     download source for this version

     these are represented by the following:
     the desired pointer in the packagemetadata indicated which version we are operating on.
     if we are operating on the installed version, reinstall is a valid option.
     for the selected version, forceinstall means Do an install no matter what, and
     srcpicked means download the source.

     The default action for any installed package is to install the 'curr version'
     if it is not already installed.

     The default action for any non-installed package is to do nothing.

     To achieve a no-op, set desired==installed, and if (installed) set forceinstall=0 and
     srcpicked = 0;

     Iteration through versions should follow the following rules:
     selected radio button (prev/curr/test) (show as reinstall if that is the
     current version) ->source only (only if the package is installed) ->oldest version....s
     kip version of radio button...
     newest version->uninstall->no-op->selected radio button.

     If any state cannot be set (ie because (say) no prev entry exists for a package
     simply progress to the next option.

   */

  /* We were set to uninstall the package */
  if (!desired && installed)
    {
      /* No-op - keep whatever we've got */
      desired = installed;
      if (desired)
	{
	  desired.pick (false, NULL);
	  desired.sourcePackage().pick (false, NULL);
	}
      return;
    }
  else if (desired == installed &&
	   (!installed || 
	    // neither bin nor source are being installed
	    (!(installed.picked() || installed.sourcePackage().picked()) &&
	     // bin or source are available
	     (installed.accessible() || installed.sourcePackage().accessible()) ))
	   )
    /* Install the default trust version - this is a 'reinstall' for installed
       * packages */
    {
      /* No-op */
      desired = default_version;
      if (desired)
	{
	  if (desired.accessible())
	    desired.pick (true, this);
	  else
	    desired.sourcePackage().pick (true, NULL);
	  return;
	}
    }
  /* are we currently on the radio button selection and installed */
  if (desired == default_version && installed &&
      (!desired || desired.picked())
      && (desired && desired.sourcePackage().accessible())
      )
    {
      /* source only this file */
      desired = installed;
      desired.pick (false, NULL);
      desired.sourcePackage().pick (true, NULL);
      return;
    }
  /* are we currently on source only or on the radio button but not installed */
  else if ((desired == installed 
	    && installed.sourcePackage().picked ()) || desired == default_version)
    {
      /* move onto the loop through versions */
      set<packageversion>::iterator i = versions.begin();
      if (*i == default_version)
	++i;
      if (i != versions.end())
	{
	  desired = *i;
	  desired.pick (desired.accessible(), this);
	  desired.sourcePackage ().pick (false, NULL);
	}
      else
	desired = packageversion ();
      return;
    }
  else
    {
      /* preserve the src tick box */
      bool sourceticked = desired.sourcePackage().picked();
      /* bump the version selected, skipping the radio button trust along the way */
      set<packageversion>::iterator i;
      for (i=versions.begin(); i != versions.end() && *i != desired; ++i);
      /* i points at desired in the versions set */
      ++i;
      if (i != versions.end ())
	{
	  if (default_version == *i)
	    ++i;
	  if (i != versions.end ())
	    {
	      desired = *i;
	      desired.pick (desired.accessible(), this);
	      if (desired.sourcePackage().accessible ())
		desired.sourcePackage ().pick (sourceticked, NULL);
	      else
		desired.sourcePackage ().pick (false, NULL);
	      return;
	    }
	}
      /* went past the end - uninstall the package */
      desired = packageversion ();
    }
}

int
packagemeta::set_requirements (trusts deftrust, size_t depth)
{
  if (visited())
    return 0;
  /* Only prevent further checks once we have been required by something else */
  if (depth)
    visited(true);
  int changed = 0;
  /* handle build-depends */
  if (depth == 0 && desired.sourcePackage ().picked())
    changed += desired.sourcePackage ().set_requirements (deftrust, depth + 1);
  if (!desired || (desired != installed && !desired.picked ()))
    /* uninstall || source only */
    return changed;

  return changed + desired.set_requirements (deftrust, depth);
}


// Set a particular type of action.
void
packagemeta::set_action (_actions action, packageversion const &default_version)
{
  if (action == Default_action)
    {
      if (installed
	  || categories.find ("Base") != categories.end ()
	  || categories.find ("Misc") != categories.end ())
	{
	  desired = default_version;
	  if (desired)
	    {
	      desired.pick (desired != installed, this);
	      desired.sourcePackage ().pick (false, NULL);
	    }
	}
      else
	desired = packageversion ();
      return;
    }
  else if (action == Install_action)
    {
      desired = default_version;
      if (desired)
	{
	  if (desired != installed)
	    if (desired.accessible ())
	      {
		desired.pick (true, this);
		desired.sourcePackage ().pick (false, NULL);
	      }
	    else
	      {
		desired.pick (false, NULL);
		desired.sourcePackage ().pick (true, NULL);
	      }
	  else
	    {
	      desired.pick (false, NULL);
	      desired.sourcePackage ().pick (false, NULL);
	    }
	}
      return;
    }
  else if (action == Reinstall_action)
    {
      desired = installed;
      if (desired)
	{
	  desired.pick (true, this);
	  desired.sourcePackage ().pick (false, NULL);
	}
    }
  else if (action == Uninstall_action)
    {
      desired = packageversion ();
    }
}

bool
packagemeta::accessible () const
{
  for (set<packageversion>::iterator i=versions.begin();
       i != versions.end(); ++i)
    if (i->accessible())
      return true;
  return false;
}

bool
packagemeta::sourceAccessible () const
{
  for (set<packageversion>::iterator i=versions.begin();
       i != versions.end(); ++i)
    {
      packageversion bin=*i;
      if (bin.sourcePackage().accessible())
        return true;
    }
  return false;
}

void
packagemeta::logAllVersions () const
{
    for (set<packageversion>::iterator i = versions.begin();
	 i != versions.end(); ++i) 
      {
	log (LOG_BABBLE) << "   name:" << i->Name()
	  << ", [" << trustLabel(*i)
	  << "] ver=" << i->Canonical_version()
	  << endLog;
	if (i->depends()->size()) 
	{
	  std::ostream & logger = log (LOG_BABBLE);
	  logger << "      depends=";
	  dumpAndList(i->depends(), logger);
	  logger << endLog;
	}
      }
#if 0
    log (LOG_BABBLE) << "      inst=" << i->
      /* FIXME: Reinstate this code, but spit out all mirror sites */

      for (int t = 1; t < NTRUST; t++)
	{
	  if (pkg->info[t].install)
	    log (LOG_BABBLE) << "     [%s] ver=%s\n"
		 "          inst=%s %d exists=%s\n"
		 "          src=%s %d exists=%s",
		 infos[t],
		 pkg->info[t].version ? : "(none)",
		 pkg->info[t].install ? : "(none)",
		 pkg->info[t].install_size,
		 (pkg->info[t].install_exists) ? "yes" : "no",
		 pkg->info[t].source ? : "(none)",
		 pkg->info[t].source_size,
		 (pkg->info[t].source_exists) ? "yes" : "no");
	}
#endif
}

std::string 
packagemeta::trustLabel(packageversion const &aVersion) const
{
    if (aVersion == prev)
	return "Prev";
    if (aVersion == curr)
	return "Curr";
    if (aVersion == exp)
	return "Test";
    return "Unknown";
}

void
packagemeta::visited(bool const &aBool)
{
  visited_ = aBool;
}

bool
packagemeta::visited() const
{
  return visited_;
}

void
packagemeta::logSelectionStatus() const
{
  packagemeta const & pkg = *this;
  const char *trust = ((pkg.desired == pkg.prev) ? "prev"
               : (pkg.desired == pkg.curr) ? "curr"
               : (pkg.desired == pkg.exp) ? "test" : "unknown");
  std::string action = pkg.action_caption ();
  const std::string installed =
   pkg.installed ? pkg.installed.Canonical_version () : "none";

  log (LOG_BABBLE)
	<< "[" << pkg.name << "] action=" << action
	<< " trust=" << trust
	<< " installed=" << installed
	<< " desired=" << (pkg.desired ? pkg.desired.Canonical_version() : "none" )
	<< " src?=" << (pkg.desired && pkg.desired.sourcePackage().picked() ? "yes" : "no")
	<< endLog;
  if (pkg.categories.size ())
    log (LOG_BABBLE) << "     categories=" << for_each(pkg.categories.begin(), pkg.categories.end(), StringConcatenator(", ")).result << endLog;
#if 0
  if (pkg.desired.required())
  {
    /* List other packages this package depends on */
      Dependency *dp = pkg.desired->required;
    std::string requires = dp->package.serialise ();
    for (dp = dp->next; dp; dp = dp->next)
       requires += std::string (", ") + dp->package.serialise ();

   log (LOG_BABBLE) << "     requires=" << requires;
    }
#endif
  pkg.logAllVersions();
}

void
packagemeta::ScanDownloadedFiles ()
{
  /* Look at every known package, in all the known mirror dirs,
   * and fill in the Cached attribute if it exists.
   */
  packagedb db;
  for (packagedb::packagecollection::iterator n = db.packages.begin ();
       n != db.packages.end (); ++n)
    {
      packagemeta & pkg = *(n->second);
      set<packageversion>::iterator i = pkg.versions.begin ();
      while (i != pkg.versions.end ())
	{
	  /* scan doesn't alter operator == for packageversions */
	  const_cast<packageversion &>(*i).scan ();
	  packageversion foo = *i;
	  packageversion pkgsrcver = foo.sourcePackage ();
	  pkgsrcver.scan ();

	  /* For local installs, if there is no src and no bin, the version
	   * is unavailable
	   */
	  if (!i->accessible () && !pkgsrcver.accessible ()
	      && *i != pkg.installed)
	    {
	      if (pkg.prev == *i)
		pkg.prev = packageversion ();
	      if (pkg.curr == *i)
		pkg.curr = packageversion ();
	      if (pkg.exp == *i)
		pkg.exp = packageversion ();
	      pkg.versions.erase (i++);
	      /* For now, leave the source version alone */
	    }
	  else
	    ++i;
	}
    }
    /* Don't explicity iterate through sources - any sources that aren't
       referenced are unselectable anyway.  */
}

bool
packagemeta::hasNoCategories() const
{
  return categories.size() == 0;
}

void
packagemeta::setDefaultCategories()
{
  add_category ("Misc");
}

void
packagemeta::addToCategoryAll()
{
  add_category ("All");
}

static bool
hasLic(packageversion const &pkg)
{
  //return pkg.hasLicense;
  return pkg.License().size() > 0;
}

const std::string
packagemeta::PathLicense () const
{
  set<packageversion>::iterator i = find_if (versions.begin(), versions.end(), hasLic);
  if (i == versions.end())
    return std::string();
  return i->License();
}

const bool
packagemeta::HasLicense () const
{
  set<packageversion>::iterator i = find_if (versions.begin(), versions.end(), hasLic);
  if (i == versions.end())
    return false;
  return i->HasLicense();
}
