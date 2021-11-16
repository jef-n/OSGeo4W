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

#ifndef _STRINGOPTION_H_
#define _STRINGOPTION_H_

#include <getopt++/Option.h>
#include <getopt++/GetOption.h>

// Each registered option must implement this class.
class StringOption : public Option
{
public:
  StringOption(std::string const defaultvalue, char shortopt, char const *longopt = 0,
	     std::string const &shorthelp = std::string(), bool const optional = true,
	     OptionSet &owner=GetOption::GetInstance());
  virtual ~ StringOption ();
  virtual std::string const shortOption () const;
  virtual std::string const longOption () const;
  virtual std::string const shortHelp () const;
  virtual Result Process (char const *, int);
  virtual Argument argument () const;
  operator const std::string& () const;

private:
  Argument _optional;
  std::string _value;
  char _shortopt;
  char const *_longopt;
  std::string _shorthelp;
};

#endif // _STRINGOPTION_H_
