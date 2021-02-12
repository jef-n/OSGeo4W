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

#ifndef SETUP_FINDVISITOR_H
#define SETUP_FINDVISITOR_H

#include <string>
/* For the wfd definition. See the TODO in find.cc */
#include "win32.h"

class FindVisitor
{
public:
  virtual void visitFile(const std::string& basePath,
                         WIN32_FIND_DATA const *);
  virtual void visitDirectory(const std::string& basePath,
                              WIN32_FIND_DATA const *,
			      int level);
  virtual ~ FindVisitor ();
protected:
  FindVisitor ();
  FindVisitor (FindVisitor const &);
  FindVisitor & operator= (FindVisitor const &);
};

#endif /* SETUP_FINDVISITOR_H */
