/*
 * Modified from StringOption.h by Szavai Gyula in 2011
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

#ifndef _STRINGARRAYOPTION_H_
#define _STRINGARRAYOPTION_H_

#include <getopt++/Option.h>
#include <getopt++/GetOption.h>

// Each registered option must implement this class.
class StringArrayOption : public Option
{
public:
  StringArrayOption(char shortopt, char const *longopt = 0,
	     std::string const &shorthelp = std::string(),
	     OptionSet &owner=GetOption::GetInstance());
  virtual ~ StringArrayOption ();
  virtual std::string const shortOption () const;
  virtual std::string const longOption () const;
  virtual std::string const shortHelp () const;
  virtual Result Process (char const *, int);
  virtual Argument argument () const;
  operator std::vector<std::string> () const;

private:
  Argument _optional;
  std::vector<std::string> _value;
  char _shortopt;
  char const *_longopt;
  std::string _shorthelp;
};

#endif // _STRINGARRAYOPTION_H_
