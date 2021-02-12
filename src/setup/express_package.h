/*
 * Copyright (c) 2008, Frank Warmerdam
 *
 *     This program is free software; you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation; either version 2 of the License, or
 *     (at your option) any later version.
 *
 *     A copy of the GNU General Public License can be found at
 *     http://www.gnu.org/
 *
 * Written by Frank Warmerdam <warmerdam@pobox.com>
 *
 */

#ifndef SETUP_EXPRESS_PACKAGE_H
#define SETUP_EXPRESS_PACKAGE_H

// This is the header for the ExpressPackageSetupPage class.  Allows selection
// of major packages in express mode.

#include "proppage.h"

class ExpressPackageSetupPage:public PropertyPage
{
public:
  ExpressPackageSetupPage ();
  virtual ~ ExpressPackageSetupPage () {}

  bool Create ();

  virtual void OnInit ();
  virtual void OnActivate ();
  virtual long OnBack ();
  virtual long OnNext ();
  virtual long OnUnattended ();
  virtual bool OnMessageApp (UINT uMsg, WPARAM wParam, LPARAM lParam);
};

#endif /* SETUP_EXPRESS_PACKAGE_H */
