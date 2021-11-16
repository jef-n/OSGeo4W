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

BoolOption::BoolOption(bool const defaultvalue, char shortopt,
                       char const *longopt, std::string const &shorthelp,
                       BoolOptionType type, OptionSet &owner) :
  _value (defaultvalue), _ovalue (defaultvalue), _shortopt(shortopt),
  _longopt (longopt), _shorthelp (shorthelp), _type(type)
{
  owner.Register (this);
}

BoolOption::~ BoolOption () {};

std::string const
BoolOption::shortOption () const
{
  return std::string() + _shortopt;
}

std::string const
BoolOption::longOption () const
{
  return _longopt;
}

std::vector<std::string> const &
BoolOption::longOptionPrefixes () const
{
  static std::vector<std::string> able = {"enable-", "disable-"};
  static std::vector<std::string> no = {"", "no-"};
  static std::vector<std::string> simple = {""};

  switch (_type)
    {
    case BoolOption::BoolOptionType::pairedAble:
      return able;
    case BoolOption::BoolOptionType::pairedNo:
      return no;
    case BoolOption::BoolOptionType::simple:
    default:
      return simple;
    }
}

std::string const
BoolOption::shortHelp () const
{
  return _shorthelp;
}

Option::Result
BoolOption::Process (char const *, int prefixIndex)
{
  switch (_type)
    {
    default:
    case BoolOption::BoolOptionType::simple:
      _value = !_ovalue;
    case BoolOption::BoolOptionType::pairedAble:
      _value = (prefixIndex == 0);
    case BoolOption::BoolOptionType::pairedNo:
      _value = (prefixIndex == 0);
    }

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
