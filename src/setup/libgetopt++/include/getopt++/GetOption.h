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

#ifndef _GETOPTION_H_
#define _GETOPTION_H_

#include <getopt++/OptionSet.h>

class Option;

class GetOption : public OptionSet
{
public:
  static GetOption & GetInstance ();
private:
  static GetOption *Instance;
  void Init ();
};

#endif // _GETOPTION_H_
