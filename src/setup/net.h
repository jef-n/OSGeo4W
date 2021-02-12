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

#ifndef SETUP_NET_H
#define SETUP_NET_H

// This is the header for the NetPage class.  It allows the user to select
// a proxy etc.


#include "proppage.h"

class NetPage:public PropertyPage
{
  void CheckIfEnableNext ();

public:
  NetPage ()
  {
  };
  virtual ~ NetPage ()
  {
  };

  bool Create ();

  virtual void OnInit ();
  virtual long OnNext ();
  virtual long OnBack ();
  virtual long OnUnattended ();

  virtual bool OnMessageCmd (int id, HWND hwndctl, UINT code);
};

#endif /* SETUP_NET_H */
