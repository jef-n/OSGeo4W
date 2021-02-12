/*
 * Modified from StringOption.cc by Szavai Gyula in 2011
 *
 * Copyright (c) 2002 Robert Collins.
 *
 *     This program is free software; you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation; either version 2 of the License, or
 *     (at your option) any later version.
 *
 *     A copy of the GNU General Public License can be found at
 *     http://www.gnu.org/
 */

#include <getopt++/StringArrayOption.h>

using namespace std;

StringArrayOption::StringArrayOption(char shortopt,
		       char const *longopt, string const &shorthelp,
		       OptionSet *owner) :
		       _optional(Required), _shortopt(shortopt),
		       _longopt (longopt), _shorthelp (shorthelp)
{
  if( !owner )
    owner = GetOption::GetInstance();
  owner->Register (this);
}

StringArrayOption::~ StringArrayOption () {};

string const
StringArrayOption::shortOption () const
{
  return string() + _shortopt + ":";
}

string const
StringArrayOption::longOption () const
{
  return _longopt;
}

string const
StringArrayOption::shortHelp () const
{
  return _shorthelp;
}

Option::Result
StringArrayOption::Process (char const *optarg)
{
  if (optarg)
    {
      _value.push_back(optarg);
      return Ok;
    }
  return Failed;
}

StringArrayOption::operator vector<string> () const
{
  return _value;
}

Option::Argument
StringArrayOption::argument () const
{
    return _optional;
}
