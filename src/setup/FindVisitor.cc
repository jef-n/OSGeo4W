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

#include "FindVisitor.h"
#include "find.h"

FindVisitor::FindVisitor(){}
FindVisitor::~FindVisitor(){}

// Allow non-interested visitors to skip Files.
void
FindVisitor::visitFile(const std::string& basePath, WIN32_FIND_DATA const *)
{
}

// Default to recursing through directories.
void
FindVisitor::visitDirectory(const std::string& basePath,
                            WIN32_FIND_DATA const *aDir, int level)
{
  if (level-- > 0)
    {
      Find aFinder (basePath + aDir->cFileName);
      aFinder.accept (*this, level);
    }
}
