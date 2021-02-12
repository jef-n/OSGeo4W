/*
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
main (int argc, char **argv)
{
    std::vector <Option *> const &options (GetOption::GetInstance().optionsInSet());
    if (options.size() != 1) {
	std::cout << "Incorrect number of options in optionset" << std::endl;
	return 1;
    }
    if (options[0] != &testoption) {
	std::cout << "Incorrect option in default OptionSet" << std::endl;
	return 1;
    }
    return 0;
}
