/*
 * Copyright (c) 2010 Red Hat, Inc.
 *
 *     This program is free software; you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation; either version 2 of the License, or
 *     (at your option) any later version.
 *
 *     A copy of the GNU General Public License can be found at
 *     http://www.gnu.org/
 *
 */

#ifndef SETUP_POSTINSTALL_H
#define SETUP_POSTINSTALL_H

#include "proppage.h"

class PostInstallResultsPage:public PropertyPage
{
public:
  PostInstallResultsPage ();
  virtual ~PostInstallResultsPage () { };
  bool Create ();
  virtual void OnInit ();
  virtual void OnActivate ();
  virtual long OnNext ();
  virtual long OnBack ();
  virtual long OnUnattended ();
  void SetResultsString (std::string results) { _results = results; };
 private:
  std::string _results;
};

#endif /* SETUP_POSTINSTALL_H */
