/*
 * Copyright (c) 2002 Robert Collins.
 *
 *     This program is free software; you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation; either version 2 of the License, or
 *     (at your option) any later version.
 *
 *     A copy of the GNU General Public License can be found at
 *     http://www.gnu.org/
 *
 * Written by Robert Collins <robertc@hotmail.com>
 *
 */

#include <getopt++/BoolOption.h>

using namespace std;

BoolOption::BoolOption(bool const defaultvalue, char shortopt,
		       char const *longopt, string const &shorthelp,
		       OptionSet *owner) : _value (defaultvalue),
		       _ovalue (defaultvalue), _shortopt(shortopt),
		       _longopt (longopt), _shorthelp (shorthelp)
{
  if( !owner )
	owner = GetOption::GetInstance();
  owner->Register (this);
}

BoolOption::~ BoolOption () {};

string const
BoolOption::shortOption () const
{
  return string() + _shortopt;
}

string const
BoolOption::longOption () const
{
  return _longopt;
}

string const
BoolOption::shortHelp () const
{
  return _shorthelp;
}

Option::Result
BoolOption::Process (char const *)
{
  _value = !_ovalue;
  return Ok;
}

BoolOption::operator bool () const
{
  return _value;
}

Option::Argument
BoolOption::argument () const
{
    return None;
}
