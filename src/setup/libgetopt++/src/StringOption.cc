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

#include <getopt++/StringOption.h>

StringOption::StringOption(std::string const defaultvalue, char shortopt,
		       char const *longopt, std::string const &shorthelp,
		       bool const optional, OptionSet &owner) :
		       _value (defaultvalue) , _shortopt(shortopt),
		       _longopt (longopt), _shorthelp (shorthelp)
{
  if (!optional)
    _optional = Required;
  else
    _optional = Optional;
  owner.Register (this);
}

StringOption::~ StringOption () {};

std::string const
StringOption::shortOption () const
{
  return std::string() + _shortopt + ":";
}

std::string const
StringOption::longOption () const
{
  return _longopt;
}

std::string const
StringOption::shortHelp () const
{
  return _shorthelp;
}

Option::Result
StringOption::Process (char const *optarg, int prefixIndex)
{
  if (optarg)
    _value = optarg;
  if (optarg || _optional == Optional)
      return Ok;
  return Failed;
}

StringOption::operator const std::string& () const
{
  return _value;
}

Option::Argument
StringOption::argument () const
{
    return _optional;
}
