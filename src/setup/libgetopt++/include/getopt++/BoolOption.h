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

#ifndef _BOOLOPTION_H_
#define _BOOLOPTION_H_

#include <getopt++/Option.h>
#include <getopt++/GetOption.h>

// Each registered option must implement this class.
class BoolOption : public Option
{
public:
  enum class BoolOptionType
    {
     simple,
     pairedAble,
     pairedNo,
    };

  BoolOption(bool const defaultvalue, char shortopt, char const *longopt = 0,
             std::string const &shorthelp = std::string(),
             BoolOptionType type = BoolOptionType::simple,
             OptionSet &owner=GetOption::GetInstance());
  virtual ~ BoolOption ();
  virtual std::string const shortOption () const;
  virtual std::string const longOption () const;
  virtual std::vector<std::string> const & longOptionPrefixes () const;
  virtual std::string const shortHelp () const;
  virtual Result Process (char const *, int);
  virtual Argument argument () const;
  operator bool () const;

private:
  bool _value;
  bool _ovalue;
  char _shortopt;
  char const *_longopt;
  std::string _shorthelp;
  BoolOptionType _type;
};

#endif // _BOOLOPTION_H_
