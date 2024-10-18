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
#include <string.h>

int
main (int anargc, char **anargv)
{
  BoolOption helpoption (false, 'h', "help", "Tests the use of help output.");
  BoolOption helpoption2 (false, 'o', "help2", "Tests the use of help output.");
  BoolOption ableoption (false, '\0', "foo", "Tests the use of paired option.", BoolOption::BoolOptionType::pairedAble);

  int argc=2;
  char *argv[4];
  argv[0] = strdup("BoolOptionTest");
  argv[1] = strdup("-h");
    {
      if (!GetOption::GetInstance().Process (argc, argv, NULL))
	{
	  std::cout << "Failed to process options" << std::endl;
	  return 1;
	}
      if (!helpoption)
	{
	  std::cout << "Did not receive expected help option" << std::endl;
	  return 1;
	}
      free(argv[1]);
      argc = 0;
    }
    {
      if (!GetOption::GetInstance().Process (argc, argv, NULL))
	{
	  std::cout << "Failed to process options (2) " << std::endl;
	  return 1;
	}
      if (helpoption2)
	{
	  std::cout << "Received unexpected help option" << std::endl;
	  return 1;
	}
    }
  argc=2;
  argv[0] = strdup("BoolOptionTest");
  argv[1] = strdup("--enable-foo");
    {
      if (!GetOption::GetInstance().Process (argc, argv, NULL))
        {
          std::cout << "Failed to process options (3) " << std::endl;
          return 1;
        }
      if (!ableoption)
        {
          std::cout << "Did not receive expected enable-foo option" << std::endl;
          return 1;
        }
    }
  return 0;
}
