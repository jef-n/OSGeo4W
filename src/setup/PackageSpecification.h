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

#ifndef SETUP_PACKAGESPECIFICATION_H
#define SETUP_PACKAGESPECIFICATION_H

#include <iosfwd>
#include "String++.h"
class packageversion;

/* Describe a package - i.e. we need version 5 of apt */

class PackageSpecification
{
public:
  PackageSpecification () : _packageName (), _operator(0) {}
  PackageSpecification (const std::string& packageName);
  ~PackageSpecification () {}

  class _operators;
 
  const std::string& packageName() const; 
  void setOperator (_operators const &);
  void setVersion (const std::string& );

  bool satisfies (packageversion const &) const;
  std::string serialise () const;

  PackageSpecification &operator= (PackageSpecification const &);

  friend std::ostream &operator << (std::ostream &, PackageSpecification const &);

  class _operators
    {
    public:
      _operators ():_value (0) {};
      _operators (int aInt) {
	_value = aInt;
	if (_value < 0 ||  _value > 4)
	  _value = 0;
      }
      _operators & operator ++ ();
      bool operator == (_operators const &rhs) { return _value == rhs._value; }
      bool operator != (_operators const &rhs) { return _value != rhs._value; }
      const char *caption () const;
      bool satisfies (const std::string& lhs, const std::string& rhs) const;
    private:
      int _value;
    };
  static const _operators Equals;
  static const _operators LessThan;
  static const _operators MoreThan;
  static const _operators LessThanEquals;
  static const _operators MoreThanEquals;

private:
  std::string _packageName; /* foobar */
  _operators const * _operator; /* >= */
  std::string _version;       /* 1.20 */
};

std::ostream &
operator << (std::ostream &os, PackageSpecification const &);

#endif /* SETUP_PACKAGESPECIFICATION_H */
