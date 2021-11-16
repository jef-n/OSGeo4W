/*
 * Copyright 2005-2006, Various Contributors.
 *
 *     This program is free software; you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation; either version 2 of the License, or
 *     (at your option) any later version.
 *
 *     A copy of the GNU General Public License can be found at
 *     http://www.gnu.org/
 */

#include "String++.h"
#include <sstream>
#include <algorithm>
#include <string.h>

char *
new_cstr_char_array (const std::string &s)
{
  size_t len = s.size();
  char *buf = new char[len + 1];
  if (len)
    memcpy(buf, s.c_str(), len);
  buf[len] = 0;
  return buf;
}

std::string
format_1000s (size_t num, char sep)
{
  size_t mult = 1;
  while (mult * 1000 < num)
    mult *= 1000;
  std::ostringstream os;
  os << ((num / mult) % 1000);
  for (mult /= 1000; mult > 0; mult /= 1000)
    {
      int triplet = (num / mult) % 1000;
      os << sep;
      if (triplet < 100) os << '0';
      if (triplet < 10) os << '0';
      os << triplet;
    }
  return os.str();
}

std::string
stringify (int num)
{
  std::ostringstream os;
  os << num;
  return os.str();
}

int
casecompare (const std::string& a, const std::string& b, size_t limit)
{
  size_t length_to_check = std::min(a.length(), b.length());
  if (limit && length_to_check > limit)
    length_to_check = limit;

  size_t i;
  for (i = 0; i < length_to_check; ++i)
    if (toupper(a[i]) < toupper(b[i]))
      return -1;
    else if (toupper(a[i]) > toupper(b[i]))
      return 1;

  // Hit the comparison limit without finding a difference
  if (limit && i == limit)
    return 0;

  if (a.length() < b.length())
    return -1;
  else if (a.length() > b.length())
    return 1;

  return 0;
}

std::string
replace(const std::string& haystack, const std::string& needle,
        const std::string& replacement)
{
  std::string rv(haystack);
  size_t n_len = needle.length(), r_len = replacement.length(),
         search_start = 0;

  while (true)
  {
    size_t pos = rv.find(needle, search_start);
    if (pos == std::string::npos)
      return rv;
    rv.replace(pos, n_len, replacement);
    search_start = pos + r_len;
  }
}
