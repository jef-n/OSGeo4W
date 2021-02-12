/*
 * Copyright (c) 2001, 2002, 2003 Gary R. Van Sickle.
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

#ifndef SETUP_PROPSHEET_H
#define SETUP_PROPSHEET_H

// This is the header for the PropSheet class.  This class encapsulates
// a Windows property sheet / wizard and interfaces with the PropertyPage class.
// It's named PropSheet instead of PropertySheet because the latter conflicts with
// the Windows function of the same name.


#include <vector>

#include "win32.h"
#include <prsht.h>

#include "window.h"

class PropertyPage;

class PropSheet : public Window
{
  typedef std::vector< PropertyPage* > PageContainer;
  PageContainer PropertyPages;

  HPROPSHEETPAGE *PageHandles;
  HPROPSHEETPAGE *CreatePages ();

public:
  PropSheet ();
  virtual ~ PropSheet ();

  // Should be private and friended to PropertyPage
  void SetHWNDFromPage (HWND h);
  void AdjustPageSize (HWND page);

  virtual bool Create (const Window * Parent = NULL,
		       DWORD Style =
		       WS_OVERLAPPEDWINDOW | WS_VISIBLE | WS_CLIPCHILDREN);

  void AddPage (PropertyPage * p);

  bool SetActivePage (int i);
  bool SetActivePageByID (int resource_id);
  int pageno( HWND hwnd );
  void SetButtons (DWORD flags);
  void PressButton (int button);
};

#endif /* SETUP_PROPSHEET_H */
