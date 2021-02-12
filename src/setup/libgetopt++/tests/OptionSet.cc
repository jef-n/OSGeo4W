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
#include "getopt++/StringOption.h"

#include <iostream>

class StringCollector : public Option
{
  public:
    StringCollector() : values() {}
     virtual const std::string shortOption() const
       {
	 return "";
       }
     virtual const std::string longOption() const
       {
	 return "";
       }
     virtual const std::string shortHelp() const
       {
	 return "";
       }
     virtual Option::Result Process(const char * value);
     virtual Option::Argument argument() const
       {
	 return Required;
       }
		      
     std::vector<std::string> values;
};

Option::Result
StringCollector::Process(const char * value)
{
    values.push_back(value);
    if (values.size() == 1)
	return Stop;
    return Ok;
}

int
main (int anargc, char **anargv)
{
    int argc = 1;
    char *argv[10];
    argv[0] = strdup("OptionSet");
    if (!GetOption::GetInstance().Process(argc, argv, NULL)) {
	std::cout << "Failed to process with no args" << std::endl;
	return 1;
    }
      {
	argc = 2;
	argv[1] = strdup ("nonoption");
	if (GetOption::GetInstance().Process(argc, argv, NULL)) {
	    std::cout << "Processed ok with no options and no default." << std::endl;
	    return 1;
	}
	BoolOption testoption (false, 't', "testoption", "dummy for testing OptionSet behaviour");
	if (!GetOption::GetInstance().Process(argc, argv, NULL)) {
	    std::cout << "Failed to processed with options and only nonoption arguments." << std::endl;
	    return 1;
	}
	if (GetOption::GetInstance().nonOptions().size() != 1) {
	    std::cout << "Incorrect number of non option values found" << std::endl;
	    return 1;
	}
	argc = 3;
	argv[2] = strdup ("-t");
	if (!GetOption::GetInstance().Process(argc, argv, NULL)) {
	    std::cout << "Failed to process with options and option arguments." << std::endl;
	    return 1;
	}
	if (GetOption::GetInstance().nonOptions().size() != 1) {
	    std::cout << "Incorrect number of non option values found" << std::endl;
	    return 1;
	}
	if ((bool)testoption != true) {
	    std::cout << "boolean option was not set" << std::endl;
	    return 1;
	}
	argc = 4;
	argv[3] = strdup ("--testoption");
	if (!GetOption::GetInstance().Process(argc, argv, NULL)) {
	    std::cout << "Failed to process with options and option arguments." << std::endl;
	    return 1;
	}
	if (GetOption::GetInstance().nonOptions().size() != 1) {
	    std::cout << "Incorrect number of non option values found" << std::endl;
	    return 1;
	}
	if ((bool)testoption != true) {
	    std::cout << "boolean option was not set" << std::endl;
	    return 1;
	}
	argv[argc] = strdup("-t=foo");
	++argc;
	if (GetOption::GetInstance().Process(argc, argv, NULL)) {
	    std::cout << "Processed with a value to a valueless=argument." << std::endl;
	    return 1;
	}
	StringOption testrequiredstring ("default", 's', "string", "A string with required parameter", false);
	free (argv[argc - 1]);
	argv[argc - 1] = strdup ("-st");
	if (GetOption::GetInstance().Process(argc, argv, NULL)) {
	    std::cout << "Processed with a valueless value requiring argument." << std::endl;
	    return 1;
	}
	free (argv[argc - 1]);
	argv[argc - 1] = strdup ("--string");
	if (GetOption::GetInstance().Process(argc, argv, NULL)) {
	    std::cout << "Processed with a valueless value requiring argument." << std::endl;
	    return 1;
	}
	argv[argc] = strdup ("--notavalue");
	++argc;
	if (GetOption::GetInstance().Process(argc, argv, NULL)) {
	    std::cout << "Processed with a valueless value requiring argument." << std::endl;
	    return 1;
	}
	free (argv[argc - 2]);
	argv[argc - 2] = strdup ("-s");
	if (GetOption::GetInstance().Process(argc, argv, NULL)) {
	    std::cout << "Processed with a valueless value requiring argument." << std::endl;
	    return 1;
	}
	free (argv[argc - 1]);
	argv[argc - 1] = strdup ("arequiredvalue");
	if (!GetOption::GetInstance().Process(argc, argv, NULL)) {
	    std::cout << "Failed processing with a valueed value requiring argument.(1)" << std::endl;
	    return 1;
	}
	free (argv[argc - 2]);
	argv[argc - 2] = strdup ("--string");
	if (!GetOption::GetInstance().Process(argc, argv, NULL)) {
	    std::cout << "Failed processing with a valueed value requiring argument.(2)" << std::endl;
	    return 1;
	}
	
	StringOption testoptionalstring ("default", 'o', "optional", "A string with optional parameter", true);
	argv[argc] = strdup ("-ot");
	++argc;
	if (!GetOption::GetInstance().Process(argc, argv, NULL)) {
	    std::cout << "Failed processed with a valueless value optional argument." << std::endl;
	    return 1;
	}
	free (argv[argc - 1]);
	argv[argc - 1] = strdup ("-o");
	if (!GetOption::GetInstance().Process(argc, argv, NULL)) {
	    std::cout << "Failed processed with a valueless value optional argument." << std::endl;
	    return 1;
	}
	free (argv[argc - 1]);
	argv[argc - 1] = strdup ("--optional");
	if (!GetOption::GetInstance().Process(argc, argv, NULL)) {
	    std::cout << "Failed with a valueless value optional argument.(2)" << std::endl;
	    return 1;
	}
	argv[argc] = strdup ("--testoption");
	++argc;
	if (!GetOption::GetInstance().Process(argc, argv, NULL)) {
	    std::cout << "Failed with a valueless value optional argument.(3)" << std::endl;
	    return 1;
	}
	free (argv[argc - 2]);
	argv[argc - 2] = strdup ("-o");
	if (!GetOption::GetInstance().Process(argc, argv, NULL)) {
	    std::cout << "Failed with a valueless value optional argument." << std::endl;
	    return 1;
	}
	free (argv[argc - 1]);
	argv[argc - 1] = strdup ("anoptonalvalue");
	if (!GetOption::GetInstance().Process(argc, argv, NULL)) {
	    std::cout << "Failed processing with a valueed value and optional argument.(1)" << std::endl;
	    return 1;
	}
	free (argv[argc - 2]);
	argv[argc - 2] = strdup ("--optional");
	if (!GetOption::GetInstance().Process(argc, argv, NULL)) {
	    std::cout << "Failed processing with a valueed value and optional argument.(2)" << std::endl;
	    return 1;
	}

	StringCollector strings;
	if (!GetOption::GetInstance().Process(argc, argv, &strings)) {
	    std::cout << "Failed processing with a valueed value and optional argument.(3)" << std::endl;
	    return 1;
	}
	if (strings.values.size() != 1) {
	    std::cout << "Failed to stop at 1 non option." << std::endl;
	    return 1;
	}
	if (GetOption::GetInstance().remainingArgv().size() != 6) {
	    std::cout << "Incorrect number of remaining argv elements. " << GetOption::GetInstance().remainingArgv().size()  <<std::endl;
	    return 1;
	}
	
	std::vector<std::string> subparms = GetOption::GetInstance().remainingArgv();
	StringCollector strings2;
	if (!GetOption::GetInstance().Process(subparms, &strings2)) {
	    std::cout << "Failed processing with a sub paramerers." << std::endl;
	    return 1;
	}
	if (strings.values.size() != 1) {
	    std::cout << "Failed to stop at 1 non option." << std::endl;
	    return 1;
	}
	if (GetOption::GetInstance().remainingArgv().size() != 0) {
	    std::cout << "Incorrect number of remaining argv elements. (2) " << GetOption::GetInstance().remainingArgv().size()  <<std::endl;
	    for (std::vector<std::string>::const_iterator i = GetOption::GetInstance().remainingArgv().begin(); i!=GetOption::GetInstance().remainingArgv().end(); ++i)
		std::cout << *i << std::endl;
	    return 1;
	}
	
      }
    return 0;
}
