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

#ifndef SETUP_INIPARSEFINDVISITOR_H
#define SETUP_INIPARSEFINDVISITOR_H

#include "FindVisitor.h"


/* parse passed in setup.ini files from disk. */
class IniDBBuilder;
class IniParseFeedback;
/* IniParse files and create a package db when no cached .ini exists */
class IniParseFindVisitor : public FindVisitor
{
public:
  IniParseFindVisitor (IniDBBuilder &aBuilder,
                       const std::string& localroot,
                       IniParseFeedback &);
  virtual void visitFile(const std::string& basePath, const WIN32_FIND_DATA *);
  virtual ~ IniParseFindVisitor ();

  unsigned int timeStamp() const;
  std::string version() const;
  int iniCount() const;
protected:
  IniParseFindVisitor (IniParseFindVisitor const &);
  IniParseFindVisitor & operator= (IniParseFindVisitor const &);
private:
  IniDBBuilder &_Builder;
  IniParseFeedback &_feedback;
  size_t baseLength;
  int local_ini;
  unsigned int setup_timestamp;
  std::string setup_version;
};

#endif /* SETUP_INIPARSEFINDVISITOR_H */
