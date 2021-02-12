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

#ifndef _OPTION_H_
#define _OPTION_H_

#if HAVE_CONFIG_H
#include "autoconf.h"
#endif
#if HAVE_STRING_H
#include <string>
#else 
#error "<string> required"
#endif

// Each registered option must implement this class.
class Option
{
public:
  virtual ~ Option ();
  virtual std::string const shortOption () const = 0;
  virtual std::string const longOption () const = 0;
  virtual std::string const shortHelp () const = 0;
  enum Result {
      Failed,
      Ok,
      Stop
  };
  virtual Result Process (char const *) = 0;
  enum Argument {
      None,
      Optional,
      Required
  };
  virtual Argument argument () const = 0;

protected:
    Option ();
};

#endif // _OPTION_H_
