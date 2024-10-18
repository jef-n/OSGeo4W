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

#include "postinstallresults.h"
#include "resource.h"

// ---------------------------------------------------------------------------
// implements class PostInstallResultsPage
//
// postinstall errors page
// postinstall script running itself is part of the progress page
// ---------------------------------------------------------------------------

// Sizing information.
static ControlAdjuster::ControlInfo PostInstallResultsControlsInfo[] = {
  {IDC_POSTINSTALL_HEADER, CP_STRETCH, CP_TOP },
  {IDC_POSTINSTALL_EDIT,   CP_STRETCH, CP_STRETCH },
  {0, CP_LEFT, CP_TOP}
};

PostInstallResultsPage::PostInstallResultsPage ()
{
  sizeProcessor.AddControlInfo (PostInstallResultsControlsInfo);
}

bool
PostInstallResultsPage::Create ()
{
  return PropertyPage::Create (IDD_POSTINSTALL);
}

void
PostInstallResultsPage::OnInit ()
{
  // set the edit-area to a larger font
  SetDlgItemFont(IDC_POSTINSTALL_EDIT, "MS Shell Dlg", 10);
}

void
PostInstallResultsPage::OnActivate()
{
  SetDlgItemText(GetHWND(), IDC_POSTINSTALL_EDIT, _results.c_str ());
}

long
PostInstallResultsPage::OnNext ()
{
  return IDD_DESKTOP;
}

long
PostInstallResultsPage::OnBack ()
{
  return 0;
}

long
PostInstallResultsPage::OnUnattended ()
{
  // in unattended mode, we have logged the errors, so just carry on
  // XXX: would be nice to set program exit status if errors occurred...
  return 0;
}
