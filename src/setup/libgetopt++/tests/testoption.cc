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

#include "getopt++/GetOption.h"
#include "getopt++/BoolOption.h"

#include <iostream>

static BoolOption testoption (false, 't', "testoption", "Tests the use of boolean options");
static BoolOption helpoption (false, 'h', "help", "Tests the use of help output.");
int
main (int argc, char **argv)
{
  if (!GetOption::GetInstance().Process (argc, argv, NULL))
    {
      std::cout << "Failed to process options" << std::endl;
      return 1;
    }
  if (helpoption)
    {
      GetOption::GetInstance().ParameterUsage(std::cout);
    }
  if (testoption)
    {
      std::cout << "Option used" << std::endl;
      return 1;
    }
  else
    {
      std::cout << "Option not used" << std::endl;
      return 0;
    }
}
