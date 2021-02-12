/*
 * Copyright (c) 2000,2007 Red Hat, Inc.
 *
 *     This program is free software; you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation; either version 2 of the License, or
 *     (at your option) any later version.
 *
 *     A copy of the GNU General Public License can be found at
 *     http://www.gnu.org/
 *
 * Written by DJ Delorie <dj@cygnus.com>
 *
 */

#ifndef SETUP_INI_H
#define SETUP_INI_H

#include "state.h"

class io_stream;
#include <string>
class IniState;
class IniDBBuilder;
class IniParseFeedback;
void ini_init (io_stream *, IniDBBuilder *, IniParseFeedback &);
#define YYSTYPE char *

/* When setup.ini is parsed, the information is stored according to
   the declarations here.  ini.cc (via inilex and iniparse)
   initializes these structures.  choose.cc sets the action and trust
   fields.  download.cc downloads any needed files for selected
   packages (the chosen "install" field).  install.cc installs
   selected packages. */

typedef enum
{
  EXCLUDE_NONE = 0,
  EXCLUDE_BY_SETUP,
  EXCLUDE_NOT_FOUND
} excludes;

extern bool is_64bit;
#define SETUP_INI_DIR	   (is_64bit ? "x86_64/" : "x86/")
#define SETUP_INI_FILENAME (test_mode ? "setup_test.ini" : "setup.ini")
#define SETUP_BZ2_FILENAME (test_mode ? "setup_test.ini.bz2" : "setup.ini.bz2")

#ifndef OSGEO4W_MIRROR_URL
// TODO: add autoconf option
#error OSGEO4W_MIRROR_URL not set
#endif

/* The following three vars are used to facilitate error handling between the
   parser/lexer and its callers, namely ini.cc:do_remote_ini() and
   IniParseFindVisitor::visitFile().  */

extern std::string current_ini_name;  /* current filename/URL being parsed */
extern std::string yyerror_messages;  /* textual parse error messages */
extern int yyerror_count;             /* number of parse errors */
extern int yydebug;

#endif /* SETUP_INI_H */
