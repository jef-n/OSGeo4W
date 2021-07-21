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

/* this is the parent class for all package operations.
 */

#include "package_version.h"
#include "package_db.h"
#include "package_meta.h"
#include "LogSingleton.h"
#include "state.h"
#include "resource.h"
#include <algorithm>
#include "download.h"
#include "Exception.h"
#include "csu_util/version_compare.h"

using namespace std;

/* a default class to avoid special casing empty packageversions */

/* TODO place into the class header */
class _defaultversion : public _packageversion
{
public:
  _defaultversion()
    {
      // never try to free me!
      ++references;
    }
  const std::string Name(){return std::string();}
  const std::string Vendor_version() {return std::string();}
  const std::string Package_version() {return std::string();}
  const std::string Canonical_version() {return std::string();}
  void setCanonicalVersion (const std::string& ) {}
  package_status_t Status (){return package_notinstalled;}
  package_type_t Type () {return package_binary;}
  const std::string getfirstfile () {return std::string();}
  const std::string getnextfile () {return std::string();}
  const std::string SDesc () {return std::string();}
  void set_sdesc (const std::string& ) {}
  const std::string LDesc () {return std::string();}
  const std::string License () {return std::string();}
  void set_ldesc (const std::string& ) {}
  void set_autodep (const std::string& ) {}
  void set_license (const std::string& ) {}
  void uninstall (){}
  void pick(bool const &newValue){/* Ignore attempts to pick this!. Throw an exception here if you want to detect such attemtps instead */}
  virtual void addScript(Script const &) {}
  virtual std::vector <Script> &scripts() { scripts_.clear();  return scripts_;}
  virtual bool accessible () const {return false;}
  private:
    std::vector <Script> scripts_;
};
static _defaultversion defaultversion;

/* the wrapper class */
packageversion::packageversion() : data (&defaultversion)
{
  ++data->references;
}

/* Create from an actual package */
packageversion::packageversion (_packageversion *pkg)
{
  if (pkg)
    data = pkg;
  else
    data = &defaultversion;
  ++data->references;
}

packageversion::packageversion (packageversion const &existing) :
data(existing.data)
{
  ++data->references;
}

packageversion::~packageversion()
{
  if (--data->references == 0)
    delete data;
}

packageversion &
packageversion::operator= (packageversion const &rhs)
{
  ++rhs.data->references;
  if (--data->references == 0)
    delete data;
  data = rhs.data;
  return *this;
}

bool
packageversion::operator ! () const
{
  return !data->Name().size();
}

packageversion::operator bool () const
{
  return data->Name().size() > 0;
}

bool
packageversion::operator == (packageversion const &rhs) const
{
  if (this == &rhs || data == rhs.data)
    return true;
  else
    return data->Name () == rhs.data->Name() && data->Canonical_version () == rhs.data->Canonical_version();
}

bool
packageversion::operator != (packageversion const &rhs) const
{
  return ! (*this == rhs);
}

bool
packageversion::operator < (packageversion const &rhs) const
{
  int t = casecompare(data->Name(), rhs.data->Name());
  if (t < 0)
    return true;
  else if (t > 0)
    return false;
  else if (casecompare (data->Canonical_version(), rhs.data->Canonical_version()) < 0)
    return true;
  return false;
}

const std::string
packageversion::Name () const
{
  return data->Name ();
}

const std::string
packageversion::Vendor_version() const
{
  return data->Vendor_version();
}

const std::string
packageversion::Package_version() const
{
  return data->Package_version();
}

const std::string
packageversion::Canonical_version() const
{
  return data->Canonical_version();
}

void
packageversion::setCanonicalVersion (const std::string& ver)
{
  data->setCanonicalVersion (ver);
}

package_type_t
packageversion::Type () const
{
  return data->Type ();
}

const std::string
packageversion::getfirstfile ()
{
  return data->getfirstfile ();
}

const std::string
packageversion::getnextfile ()
{
  return data->getnextfile ();
}

const std::string
packageversion::SDesc () const
{
  return data->SDesc ();
}

void
packageversion::set_sdesc (const std::string& sdesc)
{
  data->set_sdesc (sdesc);
}

const std::string
packageversion::LDesc () const
{
  return data->LDesc ();
}

void
packageversion::set_ldesc (const std::string& ldesc)
{
  data->set_ldesc (ldesc);
}

const std::string
packageversion::License () const
{
  return data->License ();
}

void
packageversion::set_license (const std::string& lic)
{
  data->set_license (lic);
}

bool
packageversion::HasLicense() const
{
  return data->hasLic;
}

void
packageversion::set_hasLicense(bool pval)
{
  data->set_hasLicense(pval);
}

void
packageversion::set_autodep (const std::string& regex)
{
  data->set_autodep (regex);
}

packageversion
packageversion::sourcePackage() const
{
  return data->sourcePackage();
}

PackageSpecification &
packageversion::sourcePackageSpecification ()
{
  return data->sourcePackageSpecification ();
}

void
packageversion::setSourcePackageSpecification (PackageSpecification const &spec)
{
  data->setSourcePackageSpecification(spec);
}

vector <vector <PackageSpecification *> *> *
packageversion::depends()
{
  return &data->depends;
}

const vector <vector <PackageSpecification *> *> *
packageversion::depends() const
{
  return &data->depends;
}

vector <vector <PackageSpecification *> *> *
packageversion::predepends()
{
      return &data->predepends;
}

vector <vector <PackageSpecification *> *> *
packageversion::recommends()
{
      return &data->recommends;
}

vector <vector <PackageSpecification *> *> *
packageversion::suggests()
{
      return &data->suggests;
}

vector <vector <PackageSpecification *> *> *
packageversion::replaces()
{
      return &data->replaces;
}

vector <vector <PackageSpecification *> *> *
packageversion::conflicts()
{
      return &data->conflicts;
}

vector <vector <PackageSpecification *> *> *
packageversion::provides()
{
      return &data->provides;
}

vector <vector <PackageSpecification *> *> *
packageversion::binaries()
{
      return &data->binaries;
}

bool
packageversion::picked () const
{
  return data->picked;
}

void
packageversion::pick (bool aBool, packagemeta *pkg)
{
  data->pick(aBool);
  if (pkg && aBool)
    pkg->message.display ();
}

void
packageversion::uninstall ()
{
 data->uninstall ();
}

packagesource *
packageversion::source ()
{
  if (!data->sources.size())
    data->sources.push_back (packagesource());
  return &data->sources[0];
}

vector<packagesource> *
packageversion::sources ()
{
  return &data->sources;
}

bool
packageversion::accessible() const
{
  return data->accessible();
}

void
packageversion::scan()
{
  if (!*this)
    return;
  /* Remove mirror sites.
   * FIXME: This is a bit of a hack. a better way is to abstract
   * the availability logic to the package
   */
  try
    {
      if (!check_for_cached (*(source())) && ::source == IDC_SOURCE_CWD)
	source()->sites.clear();
    }
  catch (Exception * e)
    {
      // We can ignore these, since we're clearing the source list anyway
      if (e->errNo() == APPERR_CORRUPT_PACKAGE)
	{
	  source()->sites.clear();
	  return;
	}
      // Unexpected exception.
      throw e;
    }
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

static bool
checkForUpgradeable (PackageSpecification *spec)
{
  packagedb db;
  packagemeta *required = db.findBinary (*spec);
  if (!required || !required->installed)
    return false;
  for (set <packageversion>::iterator i = required->versions.begin();
       i != required->versions.end(); ++i)
    if (spec->satisfies (*i))
      return true;
  return false;
}

static bool
checkForSatisfiable (PackageSpecification *spec)
{
  packagedb db;
  packagemeta *required = db.findBinary (*spec);
  if (!required)
    return false;
  for (set <packageversion>::iterator i = required->versions.begin();
       i != required->versions.end(); ++i)
    if (spec->satisfies (*i))
      return true;
  return false;
}

static int
select (trusts deftrust, size_t depth, packagemeta *required,
        const packageversion &aVersion)
{
  /* preserve source */
  bool sourceticked = required->desired.sourcePackage ().picked();
  /* install this version */
  required->desired = aVersion;
  required->desired.pick (required->installed != required->desired, required);
  required->desired.sourcePackage ().pick (sourceticked, NULL);
  /* does this requirement have requirements? */
  return required->set_requirements (deftrust, depth + 1);
}

static int
processOneDependency (trusts deftrust, size_t depth,
                      PackageSpecification *spec)
{
  /* TODO: add this to a set of packages to be offered to meet the
     requirement. For now, simply set the install to the first
     satisfactory version. The user can step through the list if
     desired */
  packagedb db;
  packagemeta *required = db.findBinary (*spec);

  packageversion trusted = required->trustp(deftrust);
  if (spec->satisfies (trusted)) {
      return select (deftrust, depth, required, trusted);
  }

  log (LOG_TIMESTAMP) << "Warning, the default trust level for the binary package "
    << trusted.Name() << " of required package " << required->name
    << " does not meet the specification for " << *spec
    << endLog;

  set <packageversion>::iterator v;
  for (v = required->versions.begin();
    v != required->versions.end() && !spec->satisfies (*v); ++v);

  if (v == required->versions.end())
    {
      log (LOG_TIMESTAMP) << "No other satisfying package available." << endLog;
      return 0;
    }

  log (LOG_TIMESTAMP) << "Selecting other satisfying package " << v->Name() << " " << v->Canonical_version() << endLog;
  return select (deftrust, depth, required, *v);
}

int
packageversion::set_requirements (trusts deftrust, size_t depth)
{
  int changed = 0;
  vector <vector <PackageSpecification *> *>::iterator dp = depends ()->begin();
  /* cheap test for too much recursion */
  if (depth > 30)
    return changed;
  /* walk through each and clause */
  while (dp != depends ()->end())
    {
      /* three step:
	 1) is a satisfactory or clause installed?
	 2) is an unsatisfactory version of an or clause which has
	 a satisfactory version available installed?
	 3) is a satisfactory package available?
	 */
      /* check each or clause for an installed match */
      vector <PackageSpecification *>::iterator i =
	find_if ((*dp)->begin(), (*dp)->end(), checkForInstalled);
      if (i != (*dp)->end())
	{
	  /* we found an installed ok package */
	  /* next and clause */
	  ++dp;
	  continue;
	}
      /* check each or clause for an upgradeable version */
      i = find_if ((*dp)->begin(), (*dp)->end(), checkForUpgradeable);
      if (i != (*dp)->end())
	{
	  /* we found a package that can be up/downgraded to meet the
	     requirement. (*i is the packagespec that can be satisfied.)
	     */
	  ++dp;
	  changed += processOneDependency (deftrust, depth, *i) + 1;
	  continue;
	}
      /* check each or clause for an installable version */
      i = find_if ((*dp)->begin(), (*dp)->end(), checkForSatisfiable);
      if (i != (*dp)->end())
	{
	  /* we found a package that can be installed to meet the requirement */
	  ++dp;
	  changed += processOneDependency (deftrust, depth, *i) + 1;
	  continue;
	}
      ++dp;
    }
  return changed;
}

void
packageversion::addScript(Script const &aScript)
{
  return data->addScript (aScript);
}

std::vector <Script> &
packageversion::scripts()
{
  return data->scripts();
}

int
packageversion::compareVersions(packageversion a, packageversion b)
{
  /* Compare Vendor_version */
  int comparison = version_compare(a.Vendor_version(), b.Vendor_version());

#if DEBUG
  log (LOG_BABBLE) << "vendor version comparison " << a.Vendor_version() << " and " << b.Vendor_version() << ", result was " << comparison << endLog;
#endif

  if (comparison != 0)
    {
      return comparison;
    }

  /* Vendor_version are tied, compare Package_version */
#if DEBUG
  log (LOG_BABBLE) <<  "package version comparison " << a.Package_version() << " and " << b.Package_version() << ", result was " << comparison << endLog;
#endif

  comparison = version_compare(a.Package_version(), b.Package_version());
  return comparison;
}

/* the parent data class */

_packageversion::_packageversion ():picked (false), hasLic(false), references (0)
{
}

_packageversion::~_packageversion ()
{
}

PackageSpecification &
_packageversion::sourcePackageSpecification ()
{
  return _sourcePackage;
}

void
_packageversion::setSourcePackageSpecification (PackageSpecification const &spec)
{
  _sourcePackage = spec;
}

packageversion
_packageversion::sourcePackage ()
{
  if (!sourceVersion)
    {
      packagedb db;
      packagemeta * pkg;
      pkg = db.findSource (_sourcePackage);
      /* no valid source meta available, just return the default
	 (blank) package version
	 */
      if (!pkg)
	return sourceVersion;
      set<packageversion>::iterator i=pkg->versions.begin();
      while (i != pkg->versions.end())
	{
	  packageversion const & ver = * i;
          if (_sourcePackage.satisfies (ver))
	    sourceVersion = ver;
          ++i;
	}
    }
  return sourceVersion;
}

bool
_packageversion::accessible() const
{
  bool cached (sources.size() > 0);
  for (vector<packagesource>::const_iterator i = sources.begin();
       i!=sources.end(); ++i)
    if (!i->Cached ())
      cached = false;
  if (cached)
    return true;
  if (::source == IDC_SOURCE_CWD)
    return false;
  unsigned int retrievable = 0;
  for (vector<packagesource>::const_iterator i = sources.begin();
      i!=sources.end(); ++i)
    if (i->sites.size() || i->Cached ())
      retrievable += 1;
  return retrievable > 0;
}

void
_packageversion::addScript(Script const &aScript)
{
  scripts().push_back(aScript);
}

std::vector <Script> &
_packageversion::scripts()
{
  return scripts_;
}

void
dumpAndList (vector<vector <PackageSpecification *> *> const *currentAndList,
             std::ostream &logger)
{
  return;
  if (currentAndList)
  {
    vector<vector <PackageSpecification *> *>::const_iterator iAnd =
      currentAndList->begin();
    while (true)
    {
      if ((*iAnd)->size() > 1) log (LOG_BABBLE) << "( ";
      vector<PackageSpecification *>::const_iterator i= (*iAnd)->begin();
      while (true)
      {
        log(LOG_BABBLE) << **i;
        if (++i == (*iAnd)->end()) break;
        log(LOG_BABBLE) << " | ";
      }
      if ((*iAnd)->size() > 1) log (LOG_BABBLE) << " )";
      if (++iAnd == currentAndList->end()) break;
      log (LOG_BABBLE) << " & ";
    }
  }
}

