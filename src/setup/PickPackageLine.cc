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

#include "PickPackageLine.h"
#include "PickView.h"
#include "package_db.h"
#include "package_version.h"

void
PickPackageLine::paint (HDC hdc, HRGN unused, int x, int y, int col_num, int show_cat)
{
  int rb = y + theView.tm.tmHeight;
  int by = rb - 11; // top of box images
  std::string s;

  if (col_num == theView.current_col && pkg.installed)
    {
      TextOut (hdc, x + HMARGIN/2, y, pkg.installed.Canonical_version ().c_str(),
               (int) pkg.installed.Canonical_version ().size());
    }
  else if (col_num == theView.new_col)
    {
      // TextOut (hdc, x + HMARGIN/2 + NEW_COL_SIZE_SLOP, y, s.c_str(), s.size());
      // theView.DrawIcon (hdc, x + HMARGIN/2 + ICON_MARGIN/2 + RTARROW_WIDTH, by, theView.bm_spin);
      TextOut (hdc, x + HMARGIN/2 + ICON_MARGIN/2 + SPIN_WIDTH , y,
            pkg.action_caption ().c_str(), (int) pkg.action_caption ().size());
      theView.DrawIcon (hdc, x + HMARGIN/2, by, theView.bm_spin);
    }
  else if (col_num == theView.bintick_col)
    {
      if (/* uninstall or skip */ !pkg.desired ||
          /* current version */ pkg.desired == pkg.installed ||
          /* no source */ !pkg.desired.accessible())
        theView.DrawIcon (hdc, x + HMARGIN/2, by, theView.bm_checkna);
      else if (pkg.desired.picked())
        theView.DrawIcon (hdc, x + HMARGIN/2, by, theView.bm_checkyes);
      else
        theView.DrawIcon (hdc, x + HMARGIN/2, by, theView.bm_checkno);
    }
  else if (col_num == theView.srctick_col)
    {
      if ( /* uninstall */ !pkg.desired ||

#if 0
          /* note: I'm not sure what the logic here is.  With this following
             check enabled, clicking on the "source" box for a package that
             is already installed results it in showing "n/a", instead of a
             cross-box.  That seems very unintuitive, it should show a cross-
             box to indicate that the source is going to be downloaded and
             unpacked.  Disabling this, but leaving the code as reference
             in case there is some reason I'm missing for having it. --b.d.  */
          /* source only */ (!pkg.desired.picked()
    			 && pkg.desired.sourcePackage().picked() && pkg.desired == pkg.installed) ||
#endif
          /* when no source mirror available */
          !pkg.desired.sourcePackage().accessible())
        theView.DrawIcon (hdc, x + HMARGIN/2, by, theView.bm_checkna);
      else if (pkg.desired.sourcePackage().picked())
        theView.DrawIcon (hdc, x + HMARGIN/2, by, theView.bm_checkyes);
      else
        theView.DrawIcon (hdc, x + HMARGIN/2, by, theView.bm_checkno);
    }
  else if (col_num == theView.cat_col)
    {
      /* shows "first" category - do we want to show any? */
      if (pkg.categories.size () && show_cat)
        {
          s = pkg.getReadableCategoryList();
          TextOut (hdc, x + HMARGIN / 2, y, s.c_str(), (int) s.size());
        }
    }
  else if (col_num == theView.size_col)
    {
      size_t sz = 0;
      packageversion picked;

      /* Find the size of the package.  If user has chosen to upgrade/downgrade
         the package, use that version.  Otherwise use the currently installed
         version, or if not installed then use the version that would be chosen
         based on the current trust level (curr/prev/test).  */
      if (pkg.desired)
        picked = pkg.desired;
      else if (pkg.installed)
        picked = pkg.installed;
      else
        picked = pkg.trustp (theView.deftrust);

      /* Include the size of the binary package, and if selected, the source
         package as well.  */
      sz += picked.source()->size;
      if (picked.sourcePackage().picked())
        sz += picked.sourcePackage().source()->size;

      /* If size still 0, size must be unknown.  */
      s = (sz == 0) ? "?" : format_1000s((sz+1023)/1024) + "k";
      SIZE tw;
      GetTextExtentPoint32 (hdc, s.c_str(), (int) s.size(), &tw);
      int cw = theView.headers[col_num].width - HMARGIN - tw.cx;
      TextOut (hdc, x + cw + HMARGIN / 2, y, s.c_str(), (int) s.size());
    }
  else if (col_num == theView.pkg_col)
    {
      s = pkg.name;
      if (pkg.SDesc ().size())
        s += std::string(": ") + std::string(pkg.SDesc());
      TextOut (hdc, x + HMARGIN / 2, y, s.c_str(), (int) s.size());
    }
}

int
PickPackageLine::click (int const myrow, int const ClickedRow, int const x)
{
  // assert (myrow == ClickedRow);
  if (pkg.desired.accessible ()
      && x >= theView.headers[theView.bintick_col].x - HMARGIN / 2
      && x <= theView.headers[theView.bintick_col + 1].x - HMARGIN / 2)
    pkg.desired.pick(!pkg.desired.picked(), &pkg);
  if (pkg.desired.sourcePackage ().accessible ()
      && x >= theView.headers[theView.srctick_col].x - HMARGIN / 2
      && x <= theView.headers[theView.srctick_col + 1].x - HMARGIN / 2)
    pkg.desired.sourcePackage().pick(!pkg.desired.sourcePackage().picked(), NULL);

  if (x >= theView.headers[theView.new_col].x - HMARGIN / 2
      && x <= theView.headers[theView.new_col + 1].x - HMARGIN / 2)
    pkg.set_action (pkg.trustp(theView.deftrust));

  return 0;
}

int PickPackageLine::set_action (packagemeta::_actions action)
{
  pkg.set_action (action, pkg.trustp(theView.deftrust));
  return 1;
}
