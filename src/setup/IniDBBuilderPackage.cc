/*
 * Copyright (c) 2002, Robert Collins.
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

#include "IniDBBuilderPackage.h"

#include "csu_util/version_compare.h"

#include "setup_version.h"

#include "IniParseFeedback.h"
#include "package_db.h"
#include "package_meta.h"
#include "package_version.h"
#include "cygpackage.h"
#include "filemanip.h"
#include "license.h"
#include "ini.h"

// for strtoul
#include <string.h>
#include "LogSingleton.h"
#include "PackageSpecification.h"
#include <algorithm>

using namespace std;

IniDBBuilderPackage::IniDBBuilderPackage (IniParseFeedback const &aFeedback)
  : cp (0), cbpv (), cspv (), currentSpec (0), currentOrList (0), currentAndList (0), trust (0), _feedback (aFeedback)
{
  for( multimap<string, RestrictivePackage *>::iterator it = packagedb::blacklist.begin(); it != packagedb::blacklist.end(); ++it)
  {
    delete it->second;
  }

  packagedb::blacklist.clear();
}

IniDBBuilderPackage::~IniDBBuilderPackage()
{
}

void
IniDBBuilderPackage::buildTimestamp (const std::string& time)
{
  timestamp = strtoul (time.c_str(), 0, 0);
}

void
IniDBBuilderPackage::buildVersion (const std::string& aVersion)
{
  version = aVersion;
  if (version.size())
    {
      if (version_compare(setup_version, version) < 0)
        {
          std::string old_vers = Window::sprintf(
            "The current ini file is from a newer version of setup-%s.exe. "
            "If you have any trouble installing, please download a fresh "
            "version from http://download.osgeo.org/osgeo4w/osgeo4w-setup-%s.exe",
            is_64bit ? "x86_64" : "x86",
            is_64bit ? "x86_64" : "x86");
          _feedback.warning(old_vers.c_str());
        }
    }
}

void
IniDBBuilderPackage::buildPackage (const std::string& name)
{
#if DEBUG
  if (cp)
    {
      log (LOG_BABBLE) << "Finished with package " << cp->name << endLog;
      if (cbpv)
        {
          log (LOG_BABBLE) << "Version " << cbpv.Canonical_version() << endLog;
          log (LOG_BABBLE) << "Depends:" << endLog;
          dumpAndList (cbpv.depends(), log(LOG_BABBLE));
        }
    }
#endif
  packagedb db;
  cp = db.findBinary (PackageSpecification(name));
  if (!cp)
    {
      cp = new packagemeta (name);
      db.packages.insert (packagedb::packagecollection::value_type(cp->name,cp));
    }
  cbpv = cygpackage::createInstance (name, package_binary);
  cspv = packageversion ();
  currentSpec = NULL;
  currentOrList = NULL;
  currentAndList = NULL;
  trust = TRUST_CURR;
#if DEBUG
  log (LOG_BABBLE) << "Created package " << name << endLog;
#endif
}

void
IniDBBuilderPackage::buildPackageVersion (const std::string& version)
{
  cbpv.setCanonicalVersion (version);
  add_correct_version();
}

void
IniDBBuilderPackage::buildPackageSDesc (const std::string& theDesc)
{
  cbpv.set_sdesc(theDesc);
}

void
IniDBBuilderPackage::buildPackageLicense (const std::string& lic, unsigned char const *md5 )
{
  if(lic!="")
    { // it has a link to licence
      cbpv.set_license(lic);
      cbpv.set_hasLicense(true);

      MD5Sum sum;
      sum.set( md5 );

      packagedb::blacklist.insert( make_pair( sum.str(), new RestrictivePackage(cbpv.Name(), cbpv.Canonical_version(), lic) ) );

      log (LOG_BABBLE) << " The package <" << cbpv.Name() << "-" << cbpv.Canonical_version() << "> has a non-free license it was successfully added "<< endLog;
    }
  else
    {
      cbpv.set_license("");
      cbpv.set_hasLicense(false);
    }
}

void
IniDBBuilderPackage::buildPackageLDesc (const std::string& theDesc)
{
  cbpv.set_ldesc(theDesc);
#if DEBUG
  _feedback.warning(theDesc.c_str());
#endif
}

void
IniDBBuilderPackage::buildPackageInstall (const std::string& path)
{
  process_src (*cbpv.source(), path);
}

void
IniDBBuilderPackage::buildPackageSource (const std::string& path,
                                         const std::string& size)
{
  packagedb db;
  /* get an appropriate metadata */
  csp = db.findSource (PackageSpecification (cbpv.Name()));
  if (!csp)
    {
      /* Copy the existing meta data to a new source package */
      csp = new packagemeta (*cp);
      /* delete versions information */
      csp->versions.clear();
      csp->desired = packageversion();
      csp->installed = packageversion();
      csp->prev = packageversion();
      csp->curr = packageversion();
      csp->exp = packageversion();
      db.sourcePackages.insert (packagedb::packagecollection::value_type(csp->name,csp));
    }
  /* create a source packageversion */
  cspv = cygpackage::createInstance (cbpv.Name(), package_source);
  cspv.setCanonicalVersion (cbpv.Canonical_version());
  set<packageversion>::iterator i=find (csp->versions.begin(),
    csp->versions.end(), cspv);
  if (i == csp->versions.end())
    {
      csp->add_version (cspv);
    }
  else
    cspv = *i;

  if (!cspv.source()->Canonical())
    cspv.source()->set_canonical (path.c_str());
  cspv.source()->sites.push_back(site(parse_mirror));

  /* creates the relationship between binary and source packageversions */
  cbpv.setSourcePackageSpecification (PackageSpecification (cspv.Name()));
  PackageSpecification &spec = cbpv.sourcePackageSpecification();
  spec.setOperator (PackageSpecification::Equals);
  spec.setVersion (cbpv.Canonical_version());

  // process_src (*cspv.source(), path);
  setSourceSize (*cspv.source(), size);
}

void
IniDBBuilderPackage::buildSourceFile (unsigned char const * md5,
                                      const std::string& size,
                                      const std::string& path)
{
}

void
IniDBBuilderPackage::buildPackageTrust (int newtrust)
{
  trust = newtrust;
  if (newtrust != TRUST_UNKNOWN)
    {
      cbpv = cygpackage::createInstance (cp->name, package_binary);
      cspv = packageversion ();
    }
}

void
IniDBBuilderPackage::buildPackageCategory (const std::string& name)
{
  cp->add_category (name);
}

void
IniDBBuilderPackage::buildBeginDepends ()
{
#if DEBUG
  log (LOG_BABBLE) << "Beginning of a depends statement for " << cp->name
    << endLog;
  dumpAndList (currentAndList, log(LOG_BABBLE));
#endif
  currentSpec = NULL;
  currentOrList = NULL; /* set by the build AndListNode */
  currentAndList = cbpv.depends();
}

void
IniDBBuilderPackage::buildBeginPreDepends ()
{
#if DEBUG
  log (LOG_BABBLE) << "Beginning of a predepends statement" << endLog;
  dumpAndList (currentAndList, log(LOG_BABBLE));
#endif
  currentSpec = NULL;
  currentOrList = NULL; /* set by the build AndListNode */
  currentAndList = cbpv.predepends();
}

void
IniDBBuilderPackage::buildPriority (const std::string& priority)
{
  cp->priority = priority;
#if DEBUG
  log (LOG_BABBLE) << "Package " << cp->name << " is " << priority << endLog;
#endif
}

void
IniDBBuilderPackage::buildInstalledSize (const std::string& size)
{
  cbpv.source()->setInstalledSize (atoi(size.c_str()));
#if DEBUG
  log (LOG_BABBLE) << "Installed size for " << cp->name << " is " << cbpv.source()->installedSize() << endLog;
#endif
}

void
IniDBBuilderPackage::buildMaintainer (const std::string& ){}

/* TODO: we can multiple arch's for a given package,
   and it may befor either source or binary, so we need to either set both
   or track a third current package that points to whether we altering source
   or binary at the moment
   */
void
IniDBBuilderPackage::buildArchitecture (const std::string& arch)
{
  cp->architecture = arch;
#if DEBUG
  log (LOG_BABBLE) << "Package " << cp->name << " is for " << arch << " architectures." << endLog;
#endif
}

void
IniDBBuilderPackage::buildInstallSize (const std::string& size)
{
  setSourceSize (*cbpv.source(), size);
}

void
IniDBBuilderPackage::buildInstallMD5 (unsigned char const * md5)
{
  if (md5 && !cbpv.source()->md5.isSet())
    cbpv.source()->md5.set(md5);
}

void
IniDBBuilderPackage::buildSourceMD5 (unsigned char const * md5)
{
  if (md5 && !cspv.source()->md5.isSet())
    cspv.source()->md5.set(md5);
}

void
IniDBBuilderPackage::buildBeginRecommends ()
{
#if DEBUG
  log (LOG_BABBLE) << "Beginning of a recommends statement" << endLog;
  dumpAndList (currentAndList, log(LOG_BABBLE));
#endif
  currentSpec = NULL;
  currentOrList = NULL; /* set by the build AndListNode */
  currentAndList = cbpv.recommends();
}

void
IniDBBuilderPackage::buildBeginSuggests ()
{
#if DEBUG
  log (LOG_BABBLE) << "Beginning of a suggests statement" << endLog;
  dumpAndList (currentAndList, log(LOG_BABBLE));
#endif
  currentSpec = NULL;
  currentOrList = NULL; /* set by the build AndListNode */
  currentAndList = cbpv.suggests();
}

void
IniDBBuilderPackage::buildBeginReplaces ()
{
#if DEBUG
  log (LOG_BABBLE) << "Beginning of a replaces statement" << endLog;
  dumpAndList (currentAndList, log(LOG_BABBLE));
#endif
  currentSpec = NULL;
  currentOrList = NULL; /* set by the build AndListNode */
  currentAndList = cbpv.replaces();
}

void
IniDBBuilderPackage::buildBeginConflicts ()
{
#if DEBUG
  log (LOG_BABBLE) << "Beginning of a conflicts statement" << endLog;
  dumpAndList (currentAndList, log(LOG_BABBLE));
#endif
  currentSpec = NULL;
  currentOrList = NULL; /* set by the build AndListNode */
  currentAndList = cbpv.conflicts();
}

void
IniDBBuilderPackage::buildBeginProvides ()
{
#if DEBUG
  log (LOG_BABBLE) << "Beginning of a provides statement" << endLog;
  dumpAndList (currentAndList, log(LOG_BABBLE));
#endif
  currentSpec = NULL;
  currentOrList = NULL; /* set by the build AndListNode */
  currentAndList = cbpv.provides();
}

void
IniDBBuilderPackage::buildBeginBuildDepends ()
{
#if DEBUG
  log (LOG_BABBLE) << "Beginning of a Build-Depends statement" << endLog;
  dumpAndList (currentAndList, log(LOG_BABBLE));
#endif
  currentSpec = NULL;
  currentOrList = NULL; /* set by the build AndListNode */
  currentAndList = cspv.depends ();
}

void
IniDBBuilderPackage::buildBeginBinary ()
{
#if DEBUG
  log (LOG_BABBLE) << "Beginning of a Binary statement" << endLog;
  dumpAndList (currentAndList, log(LOG_BABBLE));
#endif
  currentSpec = NULL;
  currentOrList = NULL; /* set by the build AndListNode */
  currentAndList = cspv.binaries ();
}

void
IniDBBuilderPackage::buildDescription (const std::string& descline)
{
  if (cbpv)
    {
      cbpv.set_ldesc(cbpv.LDesc() + descline + "\n");
#if DEBUG
      log (LOG_BABBLE) << "Description for " << cp->name << ": \"" <<
        descline << "\"." << endLog;
#endif
    }
  else
    _feedback.warning ((std::string ("Attempt to set description for package")
                        + std::string(cp->name)
                        + "before creation of a version.").c_str());
}

void
IniDBBuilderPackage::buildSourceName (const std::string& name)
{
  if (cbpv)
    {
      cbpv.setSourcePackageSpecification (PackageSpecification (name));
#if DEBUG
      log (LOG_BABBLE) << "\"" << cbpv.sourcePackageSpecification() <<
        "\" is the source package for " << cp->name << "." << endLog;
#endif
    }
  else
      _feedback.warning ((std::string ("Attempt to set source for package")
                          + std::string(cp->name)
                          + "before creation of a version.").c_str());
}

void
IniDBBuilderPackage::buildSourceNameVersion (const std::string& version)
{
  if (cbpv)
    {
      cbpv.sourcePackageSpecification().setOperator (PackageSpecification::Equals);
      cbpv.sourcePackageSpecification().setVersion (version);
#if DEBUG
      log (LOG_BABBLE) << "The source version needed for " << cp->name <<
        " is " << version << "." << endLog;
#endif
    }
  else
      _feedback.warning ((std::string ("Attempt to set source version for package")
                          + std::string(cp->name)
                          + "before creation of a version.").c_str());
}

void
IniDBBuilderPackage::buildPackageListAndNode ()
{
  if (currentAndList)
    {
#if DEBUG
      log (LOG_BABBLE) << "New AND node for a package list" << endLog;
      if (currentOrList)
        {
          ostream &os = log (LOG_BABBLE);
          os << "Current OR list is :";
          for (vector<PackageSpecification *>::const_iterator i= currentOrList->begin();
               i != currentOrList->end(); ++i)
              os << endl << **i;
          os << endLog;
        }
#endif
      currentSpec = NULL;
      currentOrList = new vector<PackageSpecification *>;
      currentAndList->push_back (currentOrList);
    }
  else
    _feedback.warning ((std::string ("Attempt to add And node when no AndList"
                                     " present for package ")
                        + std::string(cp->name)).c_str());
}

void
IniDBBuilderPackage::buildPackageListOrNode (const std::string& packageName)
{
  if (currentOrList)
    {
      currentSpec = new PackageSpecification (packageName);
      currentOrList->push_back (currentSpec);
#if DEBUG
      log (LOG_BABBLE) << "New OR node in a package list refers to \"" <<
        *currentSpec << "\"." << endLog;
#endif
    }
  else
    _feedback.warning ((std::string ("Attempt to set specification for package ")
                        + std::string(cp->name)
                        + " before creation of a version.").c_str());
}

void
IniDBBuilderPackage::buildPackageListOperator (PackageSpecification::_operators const &_operator)
{
  if (currentSpec)
    {
      currentSpec->setOperator (_operator);
#if DEBUG
      log (LOG_BABBLE) << "Current specification is " << *currentSpec << "." << endLog;
#endif
    }
  else
    _feedback.warning ((std::string ("Attempt to set an operator for package ")
                        + std::string(cp->name)
                        + " with no current specification.").c_str());
}


void
IniDBBuilderPackage::buildPackageListOperatorVersion (const std::string& aVersion)
{
  if (currentSpec)
    {
      currentSpec->setVersion (aVersion);
#if DEBUG
      log (LOG_BABBLE) << "Current specification is " << *currentSpec << "." << endLog;
#endif
    }
  else
      _feedback.warning ((std::string ("Attempt to set an operator version for package ")
                          + std::string(cp->name)
                          + " with no current specification.").c_str());
}

/* privates */

void
IniDBBuilderPackage::add_correct_version()
{
  int merged = 0;
  for (set<packageversion>::iterator n = cp->versions.begin();
       !merged && n != cp->versions.end(); ++n)
    if (*n == cbpv )
      {
        packageversion ver = *n;
        /* ASSUMPTIONS:
           categories and requires are consistent for the same version across
           all mirrors
           */
        /*
          XXX: if the versions are equal but the size/md5sum are different,
          we should alert the user, as they may not be getting what they expect...
        */
        /* Copy the binary mirror across if this site claims to have an install */
        if (cbpv.source()->sites.size() )
          ver.source()->sites.push_back(site (cbpv.source()->sites.begin()->key));
        /* Copy the descriptions across */
        if (cbpv.SDesc ().size() && !n->SDesc ().size())
          ver.set_sdesc (cbpv.SDesc ());
        if (cbpv.LDesc ().size() && !n->LDesc ().size())
          ver.set_ldesc (cbpv.LDesc ());
        if (cbpv.depends()->size() && !ver.depends ()->size())
          *ver.depends() = *cbpv.depends();
        /* TODO: other package lists */
        /* Prevent dangling references */
        currentOrList = NULL;
        currentAndList = NULL;
        currentSpec = NULL;
        cbpv = *n;
        merged = 1;
#if DEBUG
        log (LOG_BABBLE) << cp->name << " merged with an existing version " << cbpv.Canonical_version() << endLog;
#endif
      }

  if (!merged)
    {
      cp->add_version (cbpv);
#if DEBUG
      log (LOG_BABBLE) << cp->name << " version " << cbpv.Canonical_version() << " added" << endLog;
#endif
    }

  /*
    Should this version be the one selected for this package at a given
    stability/trust setting?  After merging potentially multiple package
    databases, we should pick the one with the highest version number.
  */
  packageversion *v = NULL;
  switch (trust)
  {
    case TRUST_CURR:
      v = &(cp->curr);
    break;
    case TRUST_PREV:
      v = &(cp->prev);
    break;
    case TRUST_TEST:
      v = &(cp->exp);
    break;
  }

  if (v)
    {
      int comparison = packageversion::compareVersions(cbpv, *v);

      if ((bool)(*v))
        log (LOG_BABBLE) << "package " << cp->name << " comparing versions " << cbpv.Canonical_version() << " and " << v->Canonical_version() << ", result was " << comparison << endLog;

      if (comparison > 0)
        {
          *v = cbpv;
        }
    }
}

void
IniDBBuilderPackage::process_src (packagesource &src, const std::string& path)
{
  if (!src.Canonical())
    src.set_canonical (path.c_str());
  src.sites.push_back(site(parse_mirror));

  if (!cbpv.Canonical_version ().size())
    {
      fileparse f;
      if (parse_filename (path, f))
        {
          cbpv.setCanonicalVersion (f.ver);
          add_correct_version ();
        }
    }
}

void
IniDBBuilderPackage::setSourceSize (packagesource &src, const std::string& size)
{
  if (!src.size)
    src.size = atoi(size.c_str());
}

void
IniDBBuilderPackage::buildMessage (const std::string& message_id, const std::string& message)
{
  cp->set_message (message_id, message);
}

void
IniDBBuilderPackage::autodep (const std::string& file_regex, const std::string& message)
{
  cbpv.set_autodep (file_regex);
}
