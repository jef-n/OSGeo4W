/*  UserSettings.h

    Copyright (c) 2009, Christopher Faylor

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    A copy of the GNU General Public License can be found at http://www.gnu.org
*/

#ifndef SETUP_USERSETTINGS_H
#define SETUP_USERSETTINGS_H

#include <string>
#include "io_stream.h"

class UserSettings
{
private:
  struct Element
  {
    const char *key;
    const char *value;
  } **table;
  ssize_t table_len;

  std::string filename;
  std::string cwd;

public:
  static class UserSettings *global;
  UserSettings (std::string);
  static UserSettings& instance() {return *global;}

  const char *get (const char *);
  unsigned int get_index (const char *key);
  io_stream *open (const char *);
  const char *set (const char *, const char *);
  const char *set (const char *key, const std::string val) {return set (key, val.c_str ());}
  void save ();

private:
  void extend_table (ssize_t);
  io_stream *open_settings (const char *, std::string&);

};

#endif // SETUP_USERSETTINGS_H
