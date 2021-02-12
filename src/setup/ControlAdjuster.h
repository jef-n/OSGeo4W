/*
 * Copyright (c) 2003, Frank Richter <frichter@gmx.li>
 * Copyrught (c) 2003, Robert Collins <rbtcollins@hotmail.com>
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

#ifndef SETUP_CONTROLADJUSTER_H
#define SETUP_CONTROLADJUSTER_H

#include <vector>

#include "win32.h"
#include "RECTWrapper.h"

/*
  This is a helper class to move/resize controls of a dialog when it's size
  is changed. It's no fancy layouting stuff, but rather just moving them
  around - to, for example, keep controls at the bottom really at the bottom
  when the size changes.
 */

enum ControlPosition {
  CP_LEFT = 0,
  CP_TOP = CP_LEFT,
  CP_CENTERED,
  CP_RIGHT,
  CP_BOTTOM = CP_RIGHT,
  CP_STRETCH,
  CP_STRETCH_LEFTHALF,
  CP_STRETCH_TOPHALF = CP_STRETCH_LEFTHALF,
  CP_STRETCH_RIGHTHALF,
  CP_STRETCH_BOTTOMHALF = CP_STRETCH_RIGHTHALF
};

/* left and right double as top and bottom. better labels sought. */
class ControlDimension
{
  public:
    ControlDimension(long &anInt1, long &anInt2) : 
      left(anInt1), right (anInt2){}
    long &left;
    long &right;
};

class ControlAdjuster
{
public:
  struct ControlInfo
  {
    void adjust(HWND dlg, int widthChange, int heightChange) const;
    // Control ID
    int control;
    /*
     * Position specifiers.
     */
    ControlPosition horizontalPos;
    ControlPosition verticalPos;
    private:
      void adjust (ControlPosition const &how, ControlDimension &where, int by) const;
  };
  
  /*
    Adjust all the controls.
    'controlInfo' an array with the moving information.
    The terminating item of the array should have an ID <= 0.
   */
  static void AdjustControls (HWND dlg, const ControlInfo controlInfo[],
    int widthChange, int heightChange);
};

class SizeProcessor
{
  typedef std::vector<const ControlAdjuster::ControlInfo*> ControlInfos;
  ControlInfos controlInfos;
  bool rectValid;
  RECTWrapper lastRect;
public:
  SizeProcessor ();
  
  void AddControlInfo (const ControlAdjuster::ControlInfo* controlInfo);
  void UpdateSize (HWND dlg);
};

#endif // SETUP_CONTROLADJUSTER_H 
