/*
 * Copyright (c) 2000, 2001, Red Hat, Inc.
 *
 *     This program is free software; you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation; either version 2 of the License, or
 *     (at your option) any later version.
 *
 *     A copy of the GNU General Public License can be found at
 *     http://www.gnu.org/
 *
 * Written by Robert Collins <rbtcollins@redhat.com>
 *
 */

/* The purpose of this file is to put all general purpose file manipulation
   code in one place. */

#include <string.h>
#include <wchar.h>
#include <stdlib.h>
#include "filemanip.h"
#include "io_stream.h"
#include "String++.h"
#include "win32.h"
#ifndef _MSC_VER
#include "ntdll.h"
#endif
#include "io.h"
#include "fcntl.h"

using namespace std;

/* legacy wrapper.
 * Clients should use io_stream.get_size() */
size_t
get_file_size (const std::string& name)
{
  io_stream *theFile = io_stream::open (name, "rb");
  if (!theFile)
    /* To consider: throw an exception ? */
    return 0;
  ssize_t rv = theFile->get_size();
  delete theFile;
  return rv;
}

std::string
base (const std::string& aString)
{
  if (!aString.size())
    return "";
  const char *s = aString.c_str();
  std::string rv = s;
  while (*s)
    {
      if ((*s == '/' || *s == ':' || *s == '\\') && s[1])
	rv = s + 1;
      s++;
    }
  return rv;
}

/* returns the number of characters of path that
 * precede the extension
 */
int
find_tar_ext (const char *path)
{
  const char *end = strchr (path, '\0');
  /* check in longest first order */
  const char *ext;
  if ((ext = trail (path, ".tar.bz2")) && (end - ext) == 8)
    return (int) (ext - path);
  if ((ext = trail (path, ".tar.gz")) && (end - ext) == 7)
    return (int) (ext - path);
  if ((ext = trail (path, ".tar")) && (end - ext) == 4)
    return (int) (ext - path);
  return 0;
}

/* Parse a filename into package, version, and extension components. */
int
parse_filename (const string &fn, fileparse & f)
{
  char *p, *ver;
  int n;

  if (!(n = find_tar_ext (fn.c_str ())))
    return 0;

  f.pkg = "";
  f.what = "";

  f.tail = fn.substr (n, string::npos);

  p = new_cstr_char_array (base (fn.substr (0, n)));
  char const *ext;
  /* TODO: make const and non-const trail variant. */
  if ((ext = trail (p, "-src")))
    {
      f.what = "-src";
      *(char *)ext = '\0';
    }
  else if ((ext = trail (p, "-patch")))
    {
      f.what = "-patch";
      *(char *)ext = '\0';
    }
  for (ver = p; *ver; ver++)
    if (*ver == '-')
      {
        if (isdigit (ver[1]))
          {
            *ver++ = 0;
            f.pkg = p;
            break;
          }
        else if (strcasecmp (ver, "-src") == 0 ||
                 strcasecmp (ver, "-patch") == 0 )
          {
            *ver++ = 0;
            f.pkg = p;
            f.what = strlwr (ver);
            ver = strchr (ver, '\0');
            break;
          }
      }

  if (!f.pkg.size())
    f.pkg = p;

  if (!f.what.size())
    {
      int n;
      char *p1 = strchr (ver, '\0');
      if ((p1 -= 4) >= ver && strcasecmp (p1, "-src") == 0)
        n = 4;
      else if ((p1 -= 2) >= ver && strcasecmp (p1, "-patch") == 0)
        n = 6;
      else
        n = 0;
      if (n)
      {
        // get the 'src' or 'patch'.
        f.what = p1 + 1;
      }
    }

  f.ver = *ver ? ver : "0.0";
  delete[] p;
  return 1;
}

const char *
trail (const char *haystack, const char *needle)
{
  /* See if the path ends with a specific suffix.
     Just return if it doesn't. */
  size_t hlen = strlen (haystack);
  size_t nlen = strlen (needle);
  ssize_t prefix_len = hlen - nlen;
  if (prefix_len < 0
      || strcasecmp (haystack += prefix_len, needle) != 0)
    return NULL;
  return haystack;
}

std::string
backslash(const std::string& s)
{
  std::string rv(s);

  for (std::string::iterator it = rv.begin(); it != rv.end(); ++it)
    if (*it == '/')
      *it = '\\';

  return rv;
}
