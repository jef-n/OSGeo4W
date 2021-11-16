/*
 * Copyright (c) 2002,2007 Robert Collins.
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

#include "IniParseFindVisitor.h"

#include "csu_util/rfc1738.h"

#include "IniParseFeedback.h"
#include "IniDBBuilder.h"
#include "io_stream.h"
#include "ini.h"
#include <stdexcept>

using namespace std;

extern int yyparse ();

IniParseFindVisitor::IniParseFindVisitor(IniDBBuilder &aBuilder,
                                         const std::string& localroot,
                                         IniParseFeedback &feedback)
  : _Builder (aBuilder), _feedback (feedback), baseLength (localroot.size())
  , local_ini(0), setup_timestamp (0), setup_version()
{}

IniParseFindVisitor::~IniParseFindVisitor()
{}

/* look for potential packages we can add to the in-memory package
 * database
 */
void
IniParseFindVisitor::visitFile(const std::string& basePath,
                               const WIN32_FIND_DATA *theFile)
{
  //TODO: Test for case sensitivity issues
  if (casecompare(SETUP_INI_FILENAME, theFile->cFileName))
    return;

  const char *dir = basePath.c_str () + basePath.size() - strlen (SETUP_INI_DIR);
  if (dir < basePath.c_str ())
    return;
  if ((dir != basePath.c_str () && !isdirsep(dir[-1])) || casecompare (SETUP_INI_DIR, dir))
    return;

  current_ini_name = basePath + theFile->cFileName;

  io_stream *ini_file = io_stream::open("file://" + current_ini_name, "rb");

  if (!ini_file)
    // We don't throw an exception, because while this is fatal to parsing, it
    // isn't to the visitation.
    {
      // This should never happen
      // If we want to handle it happening, use the log strategy call
      throw new runtime_error ("IniParseFindVisitor: failed to open ini file, which should never happen");
      return;
    }

  _feedback.babble("Found ini file - " + current_ini_name);
  _feedback.iniName (current_ini_name);

  /* Copy leading part of path to temporary buffer and unescape it */

  size_t pos = baseLength + 1;
  size_t len = basePath.size () - (pos + strlen (SETUP_INI_DIR) + 1);
  _Builder.parse_mirror = len <= 0 ? "" : rfc1738_unescape (basePath.substr (pos, len));
  ini_init (ini_file, &_Builder, _feedback);

  /*yydebug = 1; */

  if (yyparse () || yyerror_count > 0)
    _feedback.error (yyerror_messages);
  else
    local_ini++;

  if (_Builder.timestamp > setup_timestamp)
    {
      setup_timestamp = _Builder.timestamp;
      setup_version = _Builder.version;
    }
}

int
IniParseFindVisitor::iniCount() const
{
  return local_ini;
}

unsigned int
IniParseFindVisitor::timeStamp () const
{
  return setup_timestamp;
}

std::string
IniParseFindVisitor::version() const
{
  return setup_version;
}
