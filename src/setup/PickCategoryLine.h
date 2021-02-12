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

#ifndef SETUP_PICKCATEGORYLINE_H
#define SETUP_PICKCATEGORYLINE_H


class PickView;
#include <vector>
#include "PickLine.h"
#include "package_meta.h"

class PickCategoryLine : public PickLine
{
public:
  PickCategoryLine (PickView & aView, Category & _cat, int thedepth = 0,
                    bool aBool = true, bool aBool2 = true)
    : PickLine (_cat.first)
    , current_default (packagemeta::Default_action)
    , cat (_cat), labellength (0), depth (thedepth), theView( aView )
  {
    if (aBool)
      {
        collapsed = true;
        show_label = true;
      }
    else
      {
        collapsed = false;
        show_label = aBool2;
      }
  }
  ~PickCategoryLine ()
  {
    empty ();
  }
  void ShowLabel (bool aBool = true)
  {
    show_label = aBool;
    if (!show_label)
      collapsed = false;
  }
  virtual void paint (HDC hdc, HRGN hUpdRgn, int x, int y, int row, int show_cat);
  virtual int click (int const myrow, int const ClickedRow, int const x);
  virtual int itemcount () const
  {
    if (collapsed)
      return 1;
    int t = show_label ? 1 : 0;
    for (size_t n = 0; n < bucket.size (); ++n)
        t += bucket[n]->itemcount ();
      return t;
  };
  virtual bool IsContainer (void) const
  {
    return true;
  }
  virtual void insert (PickLine & aLine)
  {
    bucket.push_back (&aLine);
  }
  void empty ();
  virtual int set_action (packagemeta::_actions);
private:
  packagemeta::_actions
  current_default;
  Category & cat;
  bool collapsed;
  bool show_label;
  size_t labellength;
  size_t spin_x;    // x-coord where the spin button starts
  size_t depth;
  PickCategoryLine (PickCategoryLine const &);
  PickCategoryLine & operator= (PickCategoryLine const &);
  std::vector < PickLine * > bucket;
  PickView& theView;
};
#endif /* SETUP_PICKCATEGORYLINE_H */
