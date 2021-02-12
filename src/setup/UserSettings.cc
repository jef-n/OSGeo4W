/*  UserSettings.cc

    Copyright (c) 2009, Christopher Faylor

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    A copy of the GNU General Public License can be found at http://www.gnu.org
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "UserSettings.h"
#include "io_stream.h"
#include "win32.h"
#include "msg.h"

class io_stream_key : public io_stream
{
  const char *key;
  std::string buf;
public:
  io_stream_key (const char *);
  ~io_stream_key ();
  int set_mtime(time_t) {return 0;}
  time_t get_mtime () {return 0;}
  size_t get_size () {return 0;}
  ssize_t read (void *buffer, size_t len) {return 0;}
  ssize_t write (const void *buffer, size_t len) {return 0;}
  ssize_t peek (void *buffer, size_t len) {return 0;}
  ssize_t tell () {return 0;}
  int seek (long, io_stream_seek_t) {return 0;}
  int error () {return 0;}
  void operator << (std::string);
  void operator << (const char *);
  friend io_stream *UserSettings::open (const char *);
};

UserSettings *UserSettings::global;

static char *
trim (char *p)
{
  p += strspn (p, " \t");
  char *q = strchr (p, '#');
  if (q)
    *q = '\0';
  for (q = strchr (p, '\0') - 1; q >= p && (*q == ' ' || *q == '\t' || *q == '\r' || *q == '\n'); q--)
    *q = '\0';
  return p;
}

inline void
UserSettings::extend_table (ssize_t i)
{
  if (i < table_len)
    return;
  table_len = i + 100;
  table = (Element **) realloc (table, sizeof (*table) * (table_len + 1));
  table[i] = NULL;
}

io_stream *
UserSettings::open_settings (const char *filename, std::string &pathname)
{
  pathname = "file://";
  pathname += cwd;
  if (!isdirsep (cwd[cwd.size () - 1]) && !isdirsep (filename[0]))
    pathname += "/";
  pathname += filename;
  io_stream *f = io_stream::open(pathname, "rt");
  if (!f)
    {
      pathname = "cygfile:///etc/setup/";
      pathname += filename;
      f = io_stream::open (pathname, "rt");
    }
  return f;
}

UserSettings::UserSettings (std::string local_dir)
  : table (NULL), table_len (-1), cwd (local_dir)
{
  global = this;
  extend_table (0);
  io_stream *f = open_settings ("setup.rc", filename);

  if (!f)
    return;

  size_t sz = f->get_size ();
  char *buf = new char [sz + 2];
  ssize_t szread = f->read (buf, sz);
  delete f;

  if (szread > 0)
    {
      buf[szread] = '\0';
      buf[szread + 1] = '\0';
      for (char *p = strtok (buf, "\n"); p; p = strtok (p, "\n"))
	{
	  char *eol = strchr (p, '\0');
	  char *thiskey = trim (p);
	  if (!*thiskey)
	    {
	      p = eol + 1;
	      continue;
	    }
	  std::string thisval;
	  const char *nl = "";
	  while (*(p = eol + 1))
	    {
	      if (*p != ' ' && *p != '\t')
		break;
	      eol = strchr (p, '\n');
	      if (eol)
		*eol = '\0';
	      else
		eol = strchr (p, '\0');
	      char *s = trim (p);
	      if (*s)
		{
		  thisval += nl;
		  thisval += s;
		  nl = "\n";
		}
	    }
	  set (thiskey, thisval);
	}
    }
  delete buf;
}

unsigned int
UserSettings::get_index (const char *key)
{
  unsigned int i;
  for (i = 0; table[i]; i++)
    if (strcmp (key, table[i]->key) == 0)
      break;
  return i;
}

const char *
UserSettings::get (const char *key)
{
  unsigned int i = get_index (key);
  const char *value = table[i] ? table[i]->value : NULL;
  msg( "GET '%s'(%d) => '%s'\n", key, i, value ? value : "NULL" );
  return value;
}

const char *
UserSettings::set (const char *key, const char *val)
{
  msg( "SET '%s' => '%s'\n", key, val);
  ssize_t i = get_index (key);
  if (table[i])
    {
      free ((void *) table[i]->key);
      free ((void *) table[i]->value);
    }
  else
    {
      extend_table (i);
      table[i] = new Element ();
      table[i + 1] = NULL;
    }
  table[i]->key = strdup (key);
  table[i]->value = strdup (val);
  return table[i]->value;
}

void
UserSettings::save ()
{
  io_stream *f = io_stream::open(filename, "wb");
  if (!f)
    return;
  for (Element **e = table; *e; e++)
    {
	  msg( "SAVE '%s' => '%s'\n", (*e)->key, (*e)->value );
      f->write ((*e)->key, strlen ((*e)->key));
      f->write ("\n", 1);
      std::string s = (*e)->value;
      s.append ("\n");
      size_t n;
      for (size_t i = 0; (n = s.find_first_of ('\n', i)) != std::string::npos; i = n + 1)
        {
          std::string elem = s.substr (i, 1 + n - i);
          f->write ("\t", 1);
          f->write (elem.c_str (), elem.length ());
        }
    }
  delete f;
}

io_stream *
UserSettings::open (const char *key)
{
  io_stream *f = new io_stream_key (key);
  return f;
}

io_stream_key::io_stream_key (const char *in_key)
  : key (in_key), buf ("")
{
}

void
io_stream_key::operator << (std::string in)
{
  buf += in;
  buf += "\n";
}

void
io_stream_key::operator << (const char *in)
{
  std::string s = in;
  *this << s;
}

io_stream_key::~io_stream_key ()
{
  if (buf.length() > 0 && buf[buf.length () - 1] == '\n')
    buf.resize (buf.length () - 1);
  UserSettings::instance().set (key, buf);
}
