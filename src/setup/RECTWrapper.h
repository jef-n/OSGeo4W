/*
 * Copyright (c) 2001,2002, Gary R. Van Sickle.
 *
 *     This program is free software; you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation; either version 2 of the License, or
 *     (at your option) any later version.
 *
 *     A copy of the GNU General Public License can be found at
 *     http://www.gnu.org/
 *
 * Written by Gary R. Van Sickle <g.r.vansickle@worldnet.att.net>
 *
 */

#ifndef SETUP_RECTWRAPPER_H
#define SETUP_RECTWRAPPER_H


#include "win32.h"

/*
Thin wrapper around GDI's RECT, mainly to allow what would otherwise have to
be a ton of "OffsetRect(&rect, 1, 2);"-type calls to be more easily written.
Also has a few gimmes like width() and height().  Note this is derived from
GDI's RECT *struct*, so that they're interchangeable, and is not a class proper.
Not a general-purpose Rectangle class, not intended to be a general-purpose
Rectangle class.
DO NOT add virtual members or you'll wreck the RECT==RECTWrapper duality.
*/

class RECTWrapper : public RECT
{
public:
  // Get interesting facts about the RECT/RECTWrapper
  int width() const { return right - left; };
  int height() const { return bottom - top; };
  POINT center() const;

  // Do interesting things to the RECT/RECTWrapper
  RECTWrapper& operator=(const RECT & r);
  void move(int x, int y);
};

inline RECTWrapper& RECTWrapper::operator=(const RECT & r)
{
  right = r.right;
  left = r.left;
  top = r.top;
  bottom = r.bottom;
  return *this;
};

inline POINT RECTWrapper::center() const
{
  // Return the center point of the rect.
  POINT retval;
  retval.x = (left + right)/2;
  retval.y = (top + bottom)/2;
  return retval;
}

inline void RECTWrapper::move(int x, int y)
{
  // Move the whole rect by [x,y].
  // Windows refers to this as offsetting.
  OffsetRect(this, x, y);
};

#endif /* SETUP_RECTWRAPPER_H */
