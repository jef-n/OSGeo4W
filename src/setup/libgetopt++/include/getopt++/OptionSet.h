/*
 * Copyright (c) 2002 Robert Collins.
 * Copyright (c) 2003 Robert Collins.
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

#ifndef _OPTIONSET_H_
#define _OPTIONSET_H_

#include <iosfwd>
#include <vector>
#include "getopt++/Option.h"

class OptionSet
{
public:
  OptionSet();
  virtual ~OptionSet();
  virtual void Register (Option *);
  virtual bool Process (int argc, char **argv, Option *nonOptionHandler);
  virtual bool Process (std::vector<std::string> const &parms, Option *nonOptionHandler);
  virtual bool process (Option *nonOptionHandler);
  virtual void ParameterUsage (std::ostream &);
  virtual std::vector<Option *> const &optionsInSet() const;
  virtual std::vector<std::string> const &nonOptions() const;
  virtual std::vector<std::string> const &remainingArgv() const;
protected:
  OptionSet (OptionSet const &);
  OptionSet &operator= (OptionSet const &);
  // force initialisation of variables
  void Init ();
private:
  void processOne();
  bool isOption(std::string::size_type) const;
  void doOption(std::string &option, std::string::size_type const &pos);
  bool doNoArgumentOption(std::string &option, std::string::size_type const &pos);
  Option * findOption(std::string &option, std::string::size_type const &pos) const;
  std::vector<Option *> options;
  std::vector<std::string> argv;
  std::vector<std::string> nonoptions;
  std::vector<std::string> remainingargv;
  Option *nonOptionHandler;
  Option::Result lastResult;
};

#endif // _OPTIONSET_H_
