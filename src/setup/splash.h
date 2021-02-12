/*
 * Copyright (c) 2001, Gary R. Van Sickle.
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

#ifndef SETUP_SPLASH_H
#define SETUP_SPLASH_H

// This is the header for the SplashPage class.  Since the splash page
// has little to do, there's not much here.

#include "proppage.h"

class SplashPage:public PropertyPage
{
public:
  SplashPage ();
  virtual ~ SplashPage () {}

  bool Create ();
  virtual void OnInit ();
  virtual long OnNext ();
  long OnUnattended () { return 0; }
};

class SplashSetting
{
public:
  SplashSetting();
  ~SplashSetting();
};

#endif /* SETUP_SPLASH_H */
