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

#ifndef SETUP_INIDBBUILDERPACKAGE_H
#define SETUP_INIDBBUILDERPACKAGE_H

#include "IniDBBuilder.h"
#include <vector>
#include "package_version.h"
class IniParseFeedback;
class packagesource;
class packagemeta;

class IniDBBuilderPackage : public IniDBBuilder
{
public:
  IniDBBuilderPackage (IniParseFeedback const &);
  ~IniDBBuilderPackage ();
  virtual void buildTimestamp (const std::string& );
  virtual void buildVersion (const std::string& );
  virtual void buildPackage (const std::string& );
  virtual void buildPackageVersion (const std::string& );
  virtual void buildPackageSDesc (const std::string& );
  virtual void buildPackageLDesc (const std::string& );
  virtual void buildPackageLicense (const std::string&, unsigned char const[16] );
  virtual void buildPackageInstall (const std::string& );
  virtual void buildPackageSource (const std::string&, const std::string&);
  virtual void buildSourceFile (unsigned char const[16],
				const std::string&,
				const std::string&);
  virtual void buildPackageTrust (int);
  virtual void buildPackageCategory (const std::string& );

  virtual void buildBeginDepends ();
  virtual void buildBeginPreDepends ();
  virtual void buildPriority (const std::string& );
  virtual void buildInstalledSize (const std::string& );
  virtual void buildMaintainer (const std::string& );
  virtual void buildArchitecture (const std::string& );
  virtual void buildInstallSize (const std::string& );
  virtual void buildInstallMD5 (unsigned char const[16]);
  virtual void buildSourceMD5 (unsigned char const[16]);
  virtual void buildBeginRecommends ();
  virtual void buildBeginSuggests ();
  virtual void buildBeginReplaces ();
  virtual void buildBeginConflicts ();
  virtual void buildBeginProvides ();
  virtual void buildBeginBuildDepends ();
  virtual void buildBeginBinary ();
  virtual void buildDescription (const std::string&);
  virtual void buildMessage (const std::string&, const std::string&);
  virtual void autodep (const std::string&, const std::string&);
  virtual void buildSourceName (const std::string& );
  virtual void buildSourceNameVersion (const std::string& );
  virtual void buildPackageListAndNode ();
  virtual void buildPackageListOrNode (const std::string& );
  virtual void buildPackageListOperator (PackageSpecification::_operators const &);
  virtual void buildPackageListOperatorVersion (const std::string& );

private:
  void add_correct_version();
  void process_src (packagesource &src, const std::string& );
  void setSourceSize (packagesource &src, const std::string& );
  void setLicenseSize (packagesource &src, const std::string& );
  packagemeta *cp;
  packageversion cbpv;
  packagemeta *csp;
  packageversion cspv;
  PackageSpecification *currentSpec;
  std::vector<PackageSpecification *> *currentOrList;
  std::vector<std::vector<PackageSpecification *> *> *currentAndList;
  int trust;
  IniParseFeedback const &_feedback;
};

#endif /* SETUP_INIDBBUILDERPACKAGE_H */
