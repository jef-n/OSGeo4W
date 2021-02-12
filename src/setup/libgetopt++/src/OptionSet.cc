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

#if HAVE_CONFIG_H
#include "autoconf.h"
#endif
#include "getopt++/OptionSet.h"
#include "getopt++/Option.h"
#include "getopt++/DefaultFormatter.h"

#include "win32.h"
#include <iostream>
#include <algorithm>

using namespace std;

bool
OptionSet::isOption(string::size_type pos) const
{
    return pos == 1 || pos == 2;
}

void
OptionSet::processOne()
{
    string &option (argv[0]);
    string::size_type pos = option.find_first_not_of("-");

    if (!isOption(pos)) {
        /* Push the non option into storage */
	if (nonOptionHandler) {
	    lastResult = nonOptionHandler->Process(option.c_str());
	} else {
	    nonoptions.push_back(option);
	    lastResult = Option::Ok;
	}
    } else {
	doOption(option, pos);
    }
}

Option *
OptionSet::findOption(string &option, string::size_type const &pos) const
{
    Option *theOption = NULL;

    for (std::vector<Option *>::const_iterator i = options.begin(); i != options.end(); 
            ++i) {
        if (pos == 1) {
            if (option[0] == (*i)->shortOption()[0]) {
                theOption = (*i);
            }
        } else {
            /* pos == 2 : todo - prefix matches */

            if (option.find((*i)->longOption()) == 0) {
                theOption = (*i);
            }
        }
    }
    return theOption;
}

bool
OptionSet::doNoArgumentOption(std::string &option, std::string::size_type const &pos)
{
    if (pos == 1 && option.size() > 1) {
	/* Parameter when none allowed */
	
	if (option.find("=") == 1)
	    /* How best to provide failure state ? */
	    return false;
	
	argv.insert(argv.begin() + 1,"-" + option.substr(1));
    }
    
    if (pos == 2) {
	if (option.find("=") != string::npos)
	    /* How best to provide failure state ? */
	    return false;
    }
    return true;
}

/* TODO: factor this better */
void
OptionSet::doOption(string &option, string::size_type const &pos)
{
    lastResult = Option::Failed;
    option.erase(0, pos);
    Option *theOption = findOption(option, pos);
    char const *optionValue = NULL;
    string value;

    if (theOption == NULL)
	return;

    switch (theOption->argument()) {

    case Option::None:
        if (!doNoArgumentOption (option, pos))
	    return;
	break;

    case Option::Optional: {
            if (pos == 1) {
                if (option.size() == 1) {
                    /* Value in next argv */

                    if (argv.size() > 1) {
                        string::size_type maybepos = argv[1].find_first_not_of("-");

                        if (!isOption(maybepos))
                            /* not an option */
                            value = argv[1];
			    argv.erase(argv.begin() + 1);
                    }
                } else {
                    /* value if present is in this argv */

                    if (option.find ("=") == 1) {
                        /* option present */
                        value = option.substr(2);
                    } else
                        /* no option present */
                        argv.insert(argv.begin() + 1,"-" + option.substr(1));
                }
            }

            if (pos == 2) {
                string::size_type vpos = option.find("=");

                if (vpos != string::npos) {
                    /* How best to provide failure state ? */

                    if (vpos == option.size() - 1)
                        /* blank value */
			return;

                    value = option.substr(vpos + 1);
                } else {
                    /* Value in next argv */

                    if (argv.size() > 1) {
                        string::size_type maybepos = argv[1].find_first_not_of("-");

                        if (!isOption(maybepos))
                            value = argv[1];
			    argv.erase(argv.begin() + 1);
                    }
                }
            }

            if (value.size()) {
		optionValue = value.c_str();
	    }

        }
	break;

    case Option::Required: {
            if (pos == 1) {
                if (option.size() == 1) {
                    /* Value in next argv */

                    if (argv.size() < 2)
                        /* but there aren't any */
			return;

                    string::size_type maybepos = argv[1].find_first_not_of("-");

                    if (isOption(maybepos))
                        /* The next argv is an option */
			return;

                    value = argv[1]; 
		    argv.erase(argv.begin() + 1);
                } else {
                    if (option.find ("=") != 1 || option.size() < 3)
                        /* no option passed */
			return;

                    value = option.substr(2);
                }

                argv.insert(argv.begin() + 1,"-" + option.substr(1));
            }

            if (pos == 2) {
                string::size_type vpos = option.find("=");

                if (vpos != string::npos) {
                    /* How best to provide failure state ? */

                    if (vpos == option.size() - 1)
			return;

                    value = option.substr(vpos + 1);
                } else {
                    /* Value in next argv */

                    if (argv.size() < 2)
                        /* but there aren't any */
			return;

                    string::size_type maybepos = argv[1].find_first_not_of("-");

                    if (isOption(maybepos))
                        /* The next argv is an option */
			return;

                    value = argv[1];
		    argv.erase(argv.begin() + 1);
                }
            } 
	    
	    optionValue = value.c_str();
        }
	break;
    } 
    lastResult = theOption->Process(optionValue);
}

OptionSet::OptionSet () {}

OptionSet::~OptionSet ()
{}

void
OptionSet::Init()
{
    options       = std::vector<Option *> ();
    argv          = std::vector<string> ();
    nonoptions    = std::vector<string> ();
    remainingargv = std::vector<string> ();
    nonOptionHandler = NULL;
}

bool
OptionSet::process (Option *aNonOptionHandler)
{
    nonOptionHandler = aNonOptionHandler;
    if (options.size() == 0 && nonOptionHandler == NULL)
        return false;

    while (argv.size()) {
	processOne();
        switch (lastResult) {

        case Option::Failed:
            return false;

        case Option::Ok:
            argv.erase(argv.begin());
            break;

        case Option::Stop:
	    if (argv.size() > 1) {
		// dies: copy(argv.begin() + 1, argv.end(), remainingargv.begin()); 
		for (std::vector<string>::iterator i = argv.begin() + 1; i != argv.end(); ++i)
		    remainingargv.push_back(*i);
	    }
            return true;
        }
    }

    return true;
}

bool
OptionSet::Process (int argc, char **argV, Option *nonOptionHandler)
{
    if (argc == 1) {
        return true;
    }

    argv.clear();
    nonoptions.clear();
    remainingargv.clear();

    for (int counter = 1; counter < argc; ++counter)
        argv.push_back(string(argV[counter]));

    return process(nonOptionHandler);
}

bool
OptionSet::Process (std::vector<std::string> const &parms, Option *nonOptionHandler)
{
    if (parms.size() == 0)
	return true;
    argv = parms;
    nonoptions.clear();
    remainingargv.clear();
    return process(nonOptionHandler);
}

//FIXME: check for conflicts.
void
OptionSet::Register (Option * anOption)
{
    for (std::vector<Option *>::const_iterator i = options.begin(); i != options.end(); ++i) {
      if( ( ( anOption->shortOption()[0]!=' ' && anOption->shortOption()[0] == (*i)->shortOption()[0] ) || anOption->longOption() == (*i)->longOption() ) && anOption->shortHelp() != (*i)->shortHelp() ) {
        std::string error;
        error = "duplicate option:";
        error += "\nnew short:" + anOption->shortOption() + " long:" + anOption->longOption() + " help:" + anOption->shortHelp();
        error += "\nexisting short:" + (*i)->shortOption() + " long:" + (*i)->longOption() + " help:" + (*i)->shortHelp();
        MessageBox (NULL, error.c_str(), "Duplicate Option", MB_ICONERROR);
        exit(1);
      }
    }

    options.push_back(anOption);
}

void
OptionSet::ParameterUsage (ostream &aStream)
{
    for_each (options.begin(), options.end(), DefaultFormatter (aStream));
}

std::vector<Option *> const &
OptionSet::optionsInSet() const
{
    return options;
}

std::vector<string> const &
OptionSet::nonOptions() const
{
    return nonoptions;
}

std::vector<string> const &
OptionSet::remainingArgv() const
{
    return remainingargv;
}
