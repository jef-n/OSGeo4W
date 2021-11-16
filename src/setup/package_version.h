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

#ifndef SETUP_PACKAGE_VERSION_H
#define SETUP_PACKAGE_VERSION_H

/* This is a package version abstrct class, that should be able to
 * arbitrate acceess to cygwin binary packages, cygwin source package,
 * and the rpm and deb equivalents of the same.
 */

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

class CategoryList;

/*Required for parsing */
#include "package_source.h"
#include "PackageSpecification.h"
#include "PackageTrust.h"
#include "script.h"
#include <vector>

typedef enum
{
  package_invalid,
  package_old,
  package_current,
  package_experimental
}
package_stability_t;

typedef enum
{
  package_notinstalled,
  package_installed
}
package_status_t;

typedef enum
{
  package_binary,
  package_source
}
package_type_t;

/* A wrapper class to be copied by value that
   references the same package.
   Nothing is virtual, because the wrapper cannot be inherited.
   However, as all the methods are implemented in the referenced
   _packageversion, that class allows virtual overriding.
   */

class _packageversion;
class packagemeta;

/* This class has pointer semantics
   Specifically: a=b does not alter the value of *a.
   */
class packageversion
{
public:
  packageversion (); /* creates an empty packageversion */
  packageversion (_packageversion *); /* used when creating an instance */
  packageversion (packageversion const &);
  ~packageversion ();
  packageversion &operator= (packageversion const &);
  bool operator ! () const; /* true if the package is invalid. (i.e.
			       uninitialised */
  operator bool () const; /* returns ! !() */
  bool operator == (packageversion const &) const; /* equality */
  bool operator != (packageversion const &) const;
  bool operator < (packageversion const &) const;
  bool operator <= (packageversion const &) const;
  bool operator > (packageversion const &) const;
  bool operator >= (packageversion const &) const;

  const std::string Name () const;
  const std::string Vendor_version () const;
  const std::string Package_version () const;
  const std::string Canonical_version () const;
  void setCanonicalVersion (const std::string& );
  package_status_t Status () const;
  package_type_t Type () const;
  const std::string getfirstfile ();
  const std::string getnextfile ();
  const std::string SDesc () const;
  void set_sdesc (const std::string& );
  const std::string LDesc () const;
  const std::string License () const;

  void set_ldesc (const std::string& );
  void set_autodep (const std::string& );
  void set_license (const std::string& );

  packageversion sourcePackage () const;
  PackageSpecification & sourcePackageSpecification ();
  void setSourcePackageSpecification (PackageSpecification const &);

  /* invariant: these never return NULL */
  std::vector <std::vector <PackageSpecification *> *> *depends(), *predepends(),
  *recommends(), *suggests(), *replaces(), *conflicts(), *provides(), *binaries();
  const std::vector <std::vector <PackageSpecification *> *> *depends() const;

  bool picked() const;   /* true if this version is to be installed */
  void pick(bool, packagemeta *); /* trigger an install/reinsall */
  bool HasLicense() const; /* return true if this package has a license*/
  void set_hasLicense(bool);

  void uninstall ();
  /* invariant: never null */
  packagesource *source(); /* where can we source the file from */
  /* invariant: never null */
  std::vector <packagesource> *sources(); /* expose the list of files.
					source() returns the 'default' file
					sources() allows managing multiple files
					in a single package
					*/

  bool accessible () const;
  /* scan for local copies */
  void scan();

  /* ensure that the depends clause is satisfied */
  int set_requirements (trusts deftrust, size_t depth = 0);

  void addScript(Script const &);
  std::vector <Script> &scripts();

  /* utility function to compare package versions */
  static int compareVersions(packageversion a, packageversion b);

private:
  _packageversion *data; /* Invariant: * data is always valid */
};

class _packageversion
{
public:
  _packageversion();
  virtual ~_packageversion();
  /* for list inserts/mgmt. */
  std::string key;
  /* name is needed here, because if we are querying a file, the data may be embedded in
     the file */
  virtual const std::string Name () = 0;
  virtual const std::string Vendor_version () = 0;
  virtual const std::string Package_version () = 0;
  virtual const std::string Canonical_version () = 0;
  virtual void setCanonicalVersion (const std::string& ) = 0;
  virtual package_status_t Status () = 0;
//  virtual package_stability_t Stability () = 0;
  virtual package_type_t Type () = 0;
  /* TODO: we should probably return a metaclass - file name & path & size & type
     - ie doc/script/binary
   */
  virtual const std::string getfirstfile () = 0;
  virtual const std::string getnextfile () = 0;
  virtual const std::string SDesc () = 0;
  virtual void set_sdesc (const std::string& ) = 0;
  virtual const std::string LDesc () = 0;
  virtual const std::string License ()= 0;

  virtual void set_ldesc (const std::string& ) = 0;
  virtual void set_autodep (const std::string& ) = 0;
  virtual void set_license (const std::string& ) = 0;

  /* only semantically meaningful for binary packages */
  /* direct link to the source package for this binary */
  /* if multiple versions exist and the source doesn't discriminate
     then the most recent is used
     */
  virtual packageversion sourcePackage ();
  virtual PackageSpecification & sourcePackageSpecification ();
  virtual void setSourcePackageSpecification (PackageSpecification const &);

  std::vector <std::vector <PackageSpecification *> *> depends, predepends, recommends,
  suggests, replaces, conflicts, provides, binaries;

  virtual void pick(bool const &newValue) { picked = newValue;}
  bool picked;	/* non zero if this version is to be installed */
		/* This will also trigger reinstalled if it is set */
  virtual void set_hasLicense(bool const &has) { hasLic = has; }
  bool hasLic;

  virtual void uninstall () = 0;
  std::vector<packagesource> sources; /* where can we source the files from */

  virtual bool accessible () const;

  /* TODO: Implement me:
     static package_meta * scan_package (io_stream *);
   */
  size_t references;
  virtual void addScript(Script const &);
  virtual std::vector <Script> &scripts();
protected:
  /* only meaningful for binary packages */
  PackageSpecification _sourcePackage;
  packageversion sourceVersion;
  std::vector <Script> scripts_;
};

// not sure where this belongs :}.
void dumpAndList (std::vector<std::vector <PackageSpecification *> *> const *currentAndList, std::ostream &);

#endif /* SETUP_PACKAGE_VERSION_H */
