/*
 * Copyright 2003-2006, Various Contributors.
 *
 *     This program is free software; you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation; either version 2 of the License, or
 *     (at your option) any later version.
 *
 *     A copy of the GNU General Public License can be found at
 *     http://www.gnu.org/
 */

#ifndef SETUP_STRING___H
#define SETUP_STRING___H

#ifdef _MSC_VER
#define PRSIZE_T "%Iu"
#elif defined(__x86_64__)
#define PRSIZE_T "%zu"
#else
#define PRSIZE_T "%u"
#endif

#include <string>

char *new_cstr_char_array (const std::string& s);

#define __TOSTRING__(X) #X
/* Note the layer of indirection here is needed to allow
   stringification of the expansion of macros, i.e. "#define foo
   bar", "TOSTRING(foo)", to yield "bar". */
#define TOSTRING(X) __TOSTRING__(X)

std::string format_1000s (size_t num, char sep = ',');

std::string stringify (int num);

int casecompare (const std::string& a, const std::string& b, size_t limit = 0);

std::string replace(const std::string& haystack, const std::string& needle,
                    const std::string& replacement);

class casecompare_lt_op
{
  public:
    bool operator() (const std::string& a, const std::string& b) const
    { return casecompare(a, b) < 0; }
};

inline std::string operator+ (const char *a, const std::string& b)
{ return std::string(a) + b; }

#endif /* SETUP_STRING___H */
