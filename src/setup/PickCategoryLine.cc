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

#include "PickCategoryLine.h"
#include "package_db.h"
#include "PickView.h"

void
PickCategoryLine::empty (void)
{
  while (bucket.size ())
    {
      PickLine *line = *bucket.begin ();
      delete line;
      bucket.erase (bucket.begin ());
    }
}

void
PickCategoryLine::paint (HDC hdc, HRGN hUpdRgn, int x, int y, int row, int show_cat)
{
  int r = y + row * theView.row_height;
  if (show_label)
    {
      int x2 = x + theView.headers[theView.cat_col].x + HMARGIN / 2 + (int) depth * TREE_INDENT;
      int by = r + (theView.tm.tmHeight / 2) - 5;

      // draw the '+' or '-' box
      theView.DrawIcon (hdc, x2, by, (collapsed ? theView.bm_treeplus : theView.bm_treeminus));

      // draw the category name
      TextOut (hdc, x2 + 11 + ICON_MARGIN, r, cat.first.c_str(), (int) cat.first.size());
      if (!labellength)
        {
          SIZE s;
          GetTextExtentPoint32 (hdc, cat.first.c_str(), (int) cat.first.size(), &s);
          labellength = s.cx;
        }

      // draw the 'spin' glyph
      spin_x = x2 + 11 + ICON_MARGIN + labellength + ICON_MARGIN;
      theView.DrawIcon (hdc, (int) spin_x, by, theView.bm_spin);

      // draw the caption ('Default', 'Install', etc)
      TextOut (hdc, (int) spin_x + SPIN_WIDTH + ICON_MARGIN, r,
               current_default.caption (), (int) strlen (current_default.caption ()));
      row++;
    }
  if (collapsed)
    return;

  // are the siblings containers?
  if (bucket.size () && bucket[0]->IsContainer ())
    {
      for (size_t n = 0; n < bucket.size (); n++)
        {
          bucket[n]->paint (hdc, hUpdRgn, x, y, row, show_cat);
          row += bucket[n]->itemcount ();
        }
    }
  else
    {
      // calculate the maximum y value we expect for this group of lines
      int max_y = y + (row + (int) bucket.size ()) * theView.row_height;

      // paint all contained rows, columnwise
      for (int i = 0; theView.headers[i].resid; i++)
        {
          RECT r;
          r.left = x + theView.headers[i].x;
          r.right = r.left + theView.headers[i].width;

          // set up a clipping mask if necessary
          if (theView.headers[i].needs_clip)
            IntersectClipRect (hdc, r.left, y, r.right, max_y);

          // draw each row in this column
          for (unsigned int n = 0; n < bucket.size (); n++)
            {
              // test for visibility
              r.top = y + ((row + n) * theView.row_height);
              r.bottom = r.top + theView.row_height;
              if (RectVisible (hdc, &r) != 0)
                bucket[n]->paint (hdc, hUpdRgn, (int)r.left, (int)r.top, i, show_cat);
            }

          // restore original clipping area
          if (theView.headers[i].needs_clip)
            SelectClipRgn (hdc, hUpdRgn);
        }
    }
}

int
PickCategoryLine::click (int const myrow, int const ClickedRow, int const x)
{
  if (myrow == ClickedRow && show_label)
    {
      if ((size_t) x >= spin_x)
	{
	  ++current_default;

	  return set_action (current_default);
	}
      else
	{
	  collapsed = !collapsed;
	  int accum_row = 0;
	  for (size_t n = 0; n < bucket.size (); ++n)
	    accum_row += bucket[n]->itemcount ();
	  return collapsed ? accum_row : -accum_row;
	}
    }
  else
    {
      int accum_row = myrow + (show_label ? 1 : 0);
      for (size_t n = 0; n < bucket.size (); ++n)
	{
	  if (accum_row + bucket[n]->itemcount () > ClickedRow)
	    return bucket[n]->click (accum_row, ClickedRow, x);
	  accum_row += bucket[n]->itemcount ();
	}
      return 0;
    }
}

int
PickCategoryLine::set_action (packagemeta::_actions action)
{
  theView.GetParent ()->SetBusy ();
  current_default = action;
  int accum_diff = 0;
  for (size_t n = 0; n < bucket.size (); n++)
      accum_diff += bucket[n]->set_action (current_default);
  theView.GetParent ()->ClearBusy ();
  return accum_diff;
}
