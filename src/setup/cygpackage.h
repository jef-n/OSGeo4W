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

#ifndef SETUP_CYGPACKAGE_H
#define SETUP_CYGPACKAGE_H

/* This is a cygwin specific package class, that should be able to
 * arbitrate access to cygwin binary packages amd cygwin source packages
 */

/* for MAX_PATH */
#include "win32.h"

#include "package_version.h"

class io_stream;

class cygpackage:public _packageversion
{
public:
  virtual const std::string Name ();
  virtual const std::string Vendor_version ();
  virtual const std::string Package_version ();
  virtual const std::string Canonical_version ();
  virtual package_status_t Status () { return status; }
  virtual package_type_t Type () { return type; }
  virtual void set_sdesc (const std::string& );
  virtual void set_ldesc (const std::string& );
  virtual void set_license (const std::string& );

  virtual const std::string SDesc () { return sdesc; }
  virtual const std::string LDesc () { return ldesc; }

  virtual const std::string License () { return license; }
  virtual void set_autodep (const std::string& );
  virtual void uninstall ();

  /* pass the name of the package when constructing */
  void setCanonicalVersion (const std::string& );


  virtual ~ cygpackage ();
  /* TODO: we should probably return a metaclass - file name & path & size & type
     - ie doc/script/binary
   */
  virtual const std::string getfirstfile ();
  virtual const std::string getnextfile ();

  /* pass the name of the package when constructing */
  static packageversion createInstance (const std::string& pkgname,
                                        const package_type_t type);

  static packageversion createInstance (const std::string& ,
                                        const std::string& ,
                                        const std::string& ,
					package_status_t const,
					package_type_t const);

private:
  cygpackage ();
  void destroy ();
  std::string name;
  std::string vendor;
  std::string packagev;
  std::string canonical;
  std::string fn;
  std::string sdesc, ldesc;
  std::string license;
  std::string autodep_regex;
  char getfilenamebuffer[MAX_PATH];

//  package_stability_t stability;
  package_status_t status;
  package_type_t type;

  io_stream *listdata, *listfile;
};

#endif /* SETUP_CYGPACKAGE_H */
