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

#ifndef _GETOPT___DEFAULTFORMATTER_H_
#define _GETOPT___DEFAULTFORMATTER_H_

#include <iostream>
#include <vector>
#include "getopt++/Option.h"

/* Show the options on the left, the short description on the right.
 * Option display must be < o_len characters in length.
 * Descriptions must be < h_len characters in length.
 * For compatibility with default terminal width o_len + h_len <= 80.
 */
class DefaultFormatter {
  private:
    const unsigned int o_len;
    const unsigned int h_len;
    const std::string s_lead;
    const std::string l_lead;
  public:
    DefaultFormatter (std::ostream &aStream)
      : o_len(35), h_len(45),
        s_lead(" -"), l_lead(" --"),
        theStream(aStream)
    {}
    DefaultFormatter (std::ostream &aStream,
		      unsigned int o_len, unsigned int h_len,
		      std::string s_lead, std::string l_lead)
      : o_len(o_len), h_len(h_len),
        s_lead(s_lead), l_lead(l_lead),
        theStream(aStream)
    {}
    void operator () (Option *anOption) {
      theStream << s_lead << anOption->shortOption ()[0]
		<< l_lead << anOption->longOption ()
		<< std::string (o_len
				- s_lead.size () - 1 - l_lead.size ()
				- anOption->longOption ().size (), ' ');
      std::string helpmsg = anOption->shortHelp();
      while (helpmsg.size() > h_len)
	{
	  // TODO: consider using a line breaking strategy here.
	  size_t pos = helpmsg.substr(0,h_len).find_last_of(" ");
	  theStream << helpmsg.substr(0,pos)
		    << std::endl << std::string (o_len, ' ');
	  helpmsg.erase (0,pos+1);
	}
      theStream << helpmsg << std::endl;
    }
    std::ostream &theStream;
};

#endif // _GETOPT___DEFAULTFORMATTER_H_
