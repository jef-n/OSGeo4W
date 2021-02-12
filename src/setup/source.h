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

#ifndef SETUP_SOURCE_H
#define SETUP_SOURCE_H

// This is the header for the SourcePage class, which lets the user
// select Download+Install, Download, or Install From Local Directory.


#include "proppage.h"

class SourcePage:public PropertyPage
{
public:
  SourcePage ();
  virtual ~ SourcePage () {}

  bool Create ();

  virtual void OnActivate ();
  virtual void OnDeactivate ();
  virtual long OnNext ();
  virtual long OnBack ();
  virtual long OnUnattended ();
};

#endif /* SETUP_SOURCE_H */
