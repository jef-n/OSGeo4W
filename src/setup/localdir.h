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

#ifndef SETUP_LOCALDIR_H
#define SETUP_LOCALDIR_H

// This is the header for the LocalDirPage class.  Allows the user to select
// the local package directory (i.e. where downloaded packages are stored).


#include "proppage.h"

class LocalDirPage:public PropertyPage
{
public:
  LocalDirPage ();
  virtual ~LocalDirPage () {}

  bool Create ();

  virtual void OnActivate ();
  virtual long OnNext ();
  virtual long OnBack ();
  virtual long OnUnattended () { return OnNext (); }
};


class LocalDirSetting
{
  public:
      LocalDirSetting();
      ~LocalDirSetting();
};

#endif /* SETUP_LOCALDIR_H */
