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
int
main (int anargc, char **anargv)
{
  int argc=2;
  char *argv[4];
  argv[0] = strdup("BoolOptionTest");
  argv[1] = strdup("-h");
    {
      BoolOption helpoption (false, 'h', "help", "Tests the use of help output.");
      if (!GetOption::GetInstance().Process (argc, argv, NULL))
	{
	  std::cout << "Failed to process options" << std::endl;
	  return 1;
	}
      if (!helpoption)
	{
	  std::cout << "Did not recieve expected help option" << std::endl;
	  return 1;
	}
      free(argv[1]);
      argc = 0;
    }
    {
      BoolOption helpoption (false, 'h', "help", "Tests the use of help output.");
      if (!GetOption::GetInstance().Process (argc, argv, NULL))
	{
	  std::cout << "Failed to process options (2) " << std::endl;
	  return 1;
	}
      if (helpoption)
	{
	  std::cout << "Recieved unexpected  help option" << std::endl;
	  return 1;
	}
    }
  return 0;
}
