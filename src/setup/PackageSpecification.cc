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

#if 0
static const char *cvsid = "\n%%% $Id: PackageSpecification.cc,v 2.4 2006/04/15 21:21:25 maxb Exp $\n";
#endif

#include "PackageSpecification.h"
#include <iostream>
#include "package_version.h"

PackageSpecification::PackageSpecification (const std::string& packageName)
  : _packageName (packageName) , _operator (0), _version ()
{
}

const std::string&
PackageSpecification::packageName () const
{
  return _packageName;
}

void
PackageSpecification::setOperator (_operators const &anOperator)
{
  _operator = &anOperator;
}

void
PackageSpecification::setVersion (const std::string& aVersion)
{
  _version = aVersion;
}

bool
PackageSpecification::satisfies (packageversion const &aPackage) const
{
  if (casecompare(_packageName, aPackage.Name()) != 0)
    return false;
  if (_operator && _version.size() 
      && !_operator->satisfies (aPackage.Canonical_version (), _version))
    return false;
  return true;
}

std::string
PackageSpecification::serialise () const
{
  return _packageName;
}

PackageSpecification &
PackageSpecification::operator= (PackageSpecification const &rhs)
{
  _packageName = rhs._packageName;
  return *this;
}

std::ostream &
operator << (std::ostream &os, PackageSpecification const &spec)
{
  os << spec._packageName;
  if (spec._operator)
    os << " " << spec._operator->caption() << " " << spec._version;
  return os;
}

const PackageSpecification::_operators PackageSpecification::Equals(0);
const PackageSpecification::_operators PackageSpecification::LessThan(1);
const PackageSpecification::_operators PackageSpecification::MoreThan(2);
const PackageSpecification::_operators PackageSpecification::LessThanEquals(3);
const PackageSpecification::_operators PackageSpecification::MoreThanEquals(4);

char const *
PackageSpecification::_operators::caption () const
{
  switch (_value)
    {
    case 0:
    return "==";
    case 1:
    return "<";
    case 2:
    return ">";
    case 3:
    return "<=";
    case 4:
    return ">=";
    }
  // Pacify GCC: (all case options are checked above)
  return "Unknown operator";
}

bool
PackageSpecification::_operators::satisfies (const std::string& lhs,
                                             const std::string& rhs) const
{
  switch (_value)
    {
    case 0:
      return casecompare(lhs, rhs) == 0;
    case 1:
      return casecompare(lhs, rhs) < 0;
    case 2:
      return casecompare(lhs, rhs) > 0;
    case 3:
      return casecompare(lhs, rhs) <= 0;
    case 4:
      return casecompare(lhs, rhs) >= 0;
    }
  return false;
}
