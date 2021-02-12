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

#ifndef SETUP_INIDBBUILDER_H
#define SETUP_INIDBBUILDER_H

#include "PackageSpecification.h"

class IniDBBuilder
{
public:
  virtual ~IniDBBuilder() {}
  virtual void buildTimestamp (const std::string& ) = 0;
  virtual void buildVersion (const std::string& ) = 0;
  virtual void buildPackage (const std::string& ) = 0;
  virtual void buildPackageVersion (const std::string& ) = 0;
  virtual void buildPackageSDesc (const std::string& ) = 0;
  virtual void buildPackageLDesc (const std::string& ) = 0;
  virtual void buildPackageLicense (const std::string&, unsigned char const[16] ) = 0;
  virtual void buildPackageInstall (const std::string& ) = 0;
  virtual void buildPackageSource (const std::string&, const std::string&) = 0;
  virtual void buildSourceFile (unsigned char const[16],
                                const std::string&, const std::string&) = 0;
  virtual void buildPackageTrust (int) = 0;
  virtual void buildPackageCategory (const std::string& ) = 0;
  virtual void buildBeginDepends () = 0;
  virtual void buildBeginPreDepends () = 0;
  virtual void buildPriority (const std::string& ) = 0;
  virtual void buildInstalledSize (const std::string& ) = 0;
  virtual void buildMaintainer (const std::string& ) = 0;
  virtual void buildArchitecture (const std::string& ) = 0;
  virtual void buildInstallSize (const std::string& ) = 0;
  virtual void buildInstallMD5 (unsigned char const[16]) = 0;
  virtual void buildSourceMD5 (unsigned char const[16]) = 0;
  virtual void buildBeginRecommends () = 0;
  virtual void buildBeginSuggests () = 0;
  virtual void buildBeginReplaces () = 0;
  virtual void buildBeginConflicts () = 0;
  virtual void buildBeginProvides () = 0;
  virtual void buildBeginBuildDepends () = 0;
  virtual void buildBeginBinary () = 0;
  virtual void buildDescription (const std::string& ) = 0;
  virtual void buildSourceName (const std::string& ) = 0;
  virtual void buildSourceNameVersion (const std::string& ) = 0;
  virtual void buildPackageListAndNode () = 0;
  virtual void buildPackageListOrNode (const std::string& ) = 0;
  virtual void buildPackageListOperator (PackageSpecification::_operators const &) = 0;
  virtual void buildPackageListOperatorVersion (const std::string& ) = 0;
  virtual void buildMessage (const std::string&, const std::string&) = 0;
  virtual void autodep (const std::string&, const std::string&) = 0;
  void set_arch (const std::string& a) { arch = a; }
  void set_release (const std::string& rel) { release = rel; }

  unsigned int timestamp;
  std::string arch;
  std::string release;
  std::string version;
  std::string parse_mirror;
};

#endif /* SETUP_INIDBBUILDER_H */
