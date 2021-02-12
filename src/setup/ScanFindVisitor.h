/*
 * Copyright (c) 2002 Robert Collins.
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

#ifndef SETUP_SCANFINDVISITOR_H
#define SETUP_SCANFINDVISITOR_H

#include "FindVisitor.h"

class IniDBBuilder;
/* Scan files and create a package db when no cached .ini exists */
class ScanFindVisitor : public FindVisitor
{
public:
  ScanFindVisitor (IniDBBuilder &aBuilder);
  virtual void visitFile(const std::string& basePath, const WIN32_FIND_DATA *);
  virtual ~ ScanFindVisitor ();
protected:
  ScanFindVisitor (ScanFindVisitor const &);
  ScanFindVisitor & operator= (ScanFindVisitor const &);
private:
  IniDBBuilder &_Builder;
};

#endif /* SETUP_SCANFINDVISITOR_H */
