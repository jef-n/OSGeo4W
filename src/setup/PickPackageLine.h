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

#ifndef SETUP_PICKPACKAGELINE_H
#define SETUP_PICKPACKAGELINE_H

class PickView;
#include "package_meta.h"
#include "PickLine.h"

class PickPackageLine:public PickLine
{
public:
  PickPackageLine (PickView &aView, packagemeta & apkg):PickLine (apkg.key), pkg (apkg), theView (aView)
  {
  };
  virtual void paint (HDC hdc, HRGN unused, int x, int y, int col_num, int show_cat);
  virtual int click (int const myrow, int const ClickedRow, int const x);
  virtual int itemcount () const
  {
    return 1;
  }
  virtual bool IsContainer (void) const
  {
    return false;
  }
  virtual void insert (PickLine &)
  {
  };
  virtual int set_action (packagemeta::_actions);
private:
  packagemeta & pkg;
  PickView & theView;
};

#endif /* SETUP_PICKPACKAGELINE_H */
