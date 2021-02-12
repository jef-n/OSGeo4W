/*
 * Copyright (c) 2003, Frank Richter <frichter@gmx.li>
 * Copyright (c) 2003, Robert Collins <rbtcollins@hotmail.com>
 *
 *     This program is free software; you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation; either version 2 of the License, or
 *     (at your option) any later version.
 *
 *     A copy of the GNU General Public License can be found at
 *     http://www.gnu.org/
 *
 * Written by Frank Richter.
 *
 */

#include "ControlAdjuster.h"
#include "RECTWrapper.h"

void ControlAdjuster::AdjustControls (HWND dlg,
				      const ControlInfo controlInfo[],
				      int widthChange, int heightChange)
{
  const ControlInfo* ci = controlInfo;

  while (ci->control > 0)
  {
    ci->adjust(dlg, widthChange,heightChange);
    ci++;
  }
}

void
ControlAdjuster::ControlInfo::adjust(HWND dlg, int widthChange, int heightChange) const
{
  HWND ctl = GetDlgItem (dlg, control);
  if (ctl == 0)
    return;
  RECTWrapper ctlRect;
  GetWindowRect (ctl, &ctlRect);
  // We want client coords.
  ScreenToClient (dlg, (LPPOINT)&ctlRect.left);
  ScreenToClient (dlg, (LPPOINT)&ctlRect.right);

  ControlDimension horizontal(ctlRect.left, ctlRect.right);
  ControlDimension vertical(ctlRect.top, ctlRect.bottom);
  /*
    Now adjust the rectangle coordinates.
   */
  adjust(horizontalPos, horizontal, widthChange);
  adjust(verticalPos, vertical, heightChange);
  /* update the windows window */
  SetWindowPos (ctl, 0, ctlRect.left, ctlRect.top,
    ctlRect.width (), ctlRect.height (), SWP_NOACTIVATE | SWP_NOZORDER);
  // If not done, weird visual glitches can occur.
  InvalidateRect (ctl, 0, false);
}

void
ControlAdjuster::ControlInfo::adjust (ControlPosition const &how, ControlDimension &where, int by) const
{
  switch (how)
    {
      case CP_LEFT:
        break;
      case CP_CENTERED:
        where.left += by/2;
        where.right += by - by/2;
        break;
      case CP_RIGHT:
        where.left += by;
        where.right += by;
        break;
      case CP_STRETCH:
        where.right += by;
        break;
      case CP_STRETCH_LEFTHALF:
        where.right += by/2;
        break;
      case CP_STRETCH_RIGHTHALF:
        where.left += by/2;
        where.right += by;
        break;
  }
}

SizeProcessor::SizeProcessor ()
{
  rectValid = false;
}

void SizeProcessor::AddControlInfo (
  const ControlAdjuster::ControlInfo* controlInfo)
{
  controlInfos.push_back (controlInfo);
}

void SizeProcessor::UpdateSize (HWND dlg)
{
  RECTWrapper clientRect;
  ::GetClientRect (dlg, &clientRect);

  if (rectValid)
    {
      const int dX = clientRect.width () - lastRect.width ();
      const int dY = clientRect.height () - lastRect.height ();

      for (size_t i = 0; i < controlInfos.size (); i++)
	ControlAdjuster::AdjustControls (dlg, controlInfos[i], dX, dY);
    }
  else
    rectValid = true;

  lastRect = clientRect;
}
