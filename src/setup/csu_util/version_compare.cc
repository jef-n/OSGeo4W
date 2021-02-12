/*
 * Copyright (c) 2004 Max Bowsher
 *
 *     This program is free software; you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation; either version 2 of the License, or
 *     (at your option) any later version.
 *
 *     A copy of the GNU General Public License can be found at
 *     http://www.gnu.org/
 *
 * Written by Max Bowsher
 */

#include "version_compare.h"

using namespace std;

static inline bool isdigit(char c) { return (c >= '0' && c <= '9'); }

/* Sort two version numbers, comparing equivalently seperated strings of
 * digits numerically.
 *
 * Returns a positive number if (a > b)
 * Returns a negative number if (a < b)
 * Returns zero if (a == b)
 *
 * Inspired but not equivalent to rpmvercmp().
 */
int version_compare (string a, string b)
{
  if (a == b) return 0;

  size_t apos1, apos2 = 0, bpos1, bpos2 = 0;
  size_t alen = a.length(), blen = b.length();
  bool isnum;
  int cval;

  while (apos2 < alen && bpos2 < blen)
  {
    apos1 = apos2;
    bpos1 = bpos2;

    if (isdigit(a[apos2]))
    {
      while (apos2 < alen && isdigit(a[apos2])) apos2++;
      while (bpos2 < blen && isdigit(b[bpos2])) bpos2++;
      isnum = true;
    }
    else
    {
      while (apos2 < alen && !isdigit(a[apos2])) apos2++;
      while (bpos2 < blen && !isdigit(b[bpos2])) bpos2++;
      isnum = false;
    }

    /* if (apos1 == apos2) { a logical impossibility has happened; } */

    /* isdigit(a[0]) != isdigit(b[0])
     * arbitrarily sort the non-digit first */
    if (bpos1 == bpos2) return (isnum ? 1 : -1);

    if (isnum)
    {
      /* skip numeric leading zeros */
      while (apos1 < alen && a[apos1] == '0') apos1++;
      while (bpos1 < blen && b[bpos1] == '0') bpos1++;

      /* if one number has more digits, it is greater */
      if (apos2-apos1 > bpos2-bpos1) return 1;
      if (apos2-apos1 < bpos2-bpos1) return -1;
    }

    /* do an ordinary lexicographic string comparison */
    cval = a.compare(apos1, apos2-apos1, b, bpos1, bpos2-bpos1);
    if (cval) return (cval < 1 ? -1 : 1);
  }

  /* ran out of characters in one string, without finding a difference */

  /* maybe they were the same version, but with different leading zeros */
  if (apos2 == alen && bpos2 == blen) return 0;

  /* the version with a suffix remaining is greater */
  return (apos2 < alen ? 1 : -1);
}

#ifdef TESTING_VERSION_COMPARE

#include <iostream>
#include <iomanip>
using namespace std;

struct version_pair
{
  const char *a;
  const char *b;
};

static version_pair test_data[] =
{
  { "1.0.0", "2.0.0" },
  { ".0.0", "2.0.0" },
  { "alpha", "beta" },
  { "1.0", "1.0.0" },
  { "2.456", "2.1000" },
  { "2.1000", "3.111" },
  { "2.001", "2.1" },
  { "2.34", "2.34" },
  { NULL, NULL }
};

int main(int argc, char* argv[])
{
  version_pair *i = test_data;

  while (i->a)
  {
    cout << setw(10) << i->a << ", " << setw(10) << i->b << " : " 
      << version_compare(i->a, i->b) << ", " << version_compare(i->b, i->a)
      << endl;
    i++;
  }

  return 0;
}

#endif
