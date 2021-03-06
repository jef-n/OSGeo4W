/*
 * Copyright (c) 2008 Frank Warmerdam
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

/* The purpose of this file is to allow selection of major packages
   in express install mode. */

#include "win32.h"
#include <shlobj.h>
#include "express_package.h"
#include "propsheet.h"
#include "threebar.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>

#include "resource.h"
#include "msg.h"
#include "state.h"
#include "dialog.h"
#include "package_db.h"
#include "package_meta.h"
#include "package_version.h"
#include "io_stream.h"
#include "getopt++/BoolOption.h"
#include "PackageSpecification.h"
#include "LogFile.h"
#include "prereq.h"
#include "threebar.h"

extern ThreeBarProgressPage Progress;

static ControlAdjuster::ControlInfo ExpressPackageControlsInfo[] = {
  {IDC_DESKTOP_SEPARATOR, 	CP_STRETCH, CP_BOTTOM},
  {IDC_STATUS, 			CP_LEFT, CP_BOTTOM},
  {IDC_STATUS_HEADER, 		CP_LEFT, CP_BOTTOM},
  {0, CP_LEFT, CP_TOP}
};

typedef struct {
    const char *package_name;
    int         control_id;
} PackageControlPair;

static const PackageControlPair PCPList[] =
{
    { "qgis-full",       IDC_PKG_QGIS},
    { "qgis-ltr-full",   IDC_PKG_QGIS_LTR},
    { "gdal",            IDC_PKG_GDAL},
    { "grass",           IDC_PKG_GRASS},
    { "",                -1}
};

static void
save_dialog( HWND h )
{
  packagedb db;

  for( int iPCP = 0; PCPList[iPCP].control_id != -1; iPCP++ )
  {
    packagemeta *pack =
      db.findBinary(PackageSpecification(PCPList[iPCP].package_name));

    if( !pack )
      continue;

    if( IsDlgButtonChecked (h, PCPList[iPCP].control_id) == BST_CHECKED )
    {
      packageversion pack_ver = pack->trustp( TRUST_CURR );

      if( !pack->installed )
      {
	pack->set_action( pack_ver );
      }
    }
#if 0
    else
    {
      if( pack->installed )
      {
	pack->installed.pick( false );
	pack->set_action( packagemeta::Uninstall_action,
	    pack->installed );
      }
    }
#endif
  }
}

static void
load_dialog( HWND h )
{
  packagedb db;
  bool express_type;

  for( int iPCP = 0; PCPList[iPCP].control_id != -1; iPCP++ )
  {
    packagemeta *pack =
      db.findBinary(PackageSpecification(PCPList[iPCP].package_name));

    if( !pack )
    {
      EnableWindow( GetDlgItem (h, PCPList[iPCP].control_id), FALSE );
      continue;
    }

    CheckDlgButton (h, PCPList[iPCP].control_id,
	pack->installed ? BST_CHECKED : BST_UNCHECKED);
  }
}

ExpressPackageSetupPage::ExpressPackageSetupPage ()
{
  sizeProcessor.AddControlInfo (ExpressPackageControlsInfo);
}

bool
ExpressPackageSetupPage::Create ()
{
  return PropertyPage::Create (IDD_EXP_PACKAGES);
}

void
ExpressPackageSetupPage::OnInit ()
{
  CoInitialize (NULL);

  SetDlgItemFont(IDC_STATUS_HEADER, "MS Shell Dlg", 8, FW_BOLD);

  if (source == IDC_SOURCE_DOWNLOAD || source == IDC_SOURCE_CWD)
    packagemeta::ScanDownloadedFiles ();
}

void
ExpressPackageSetupPage::OnActivate ()
{
  load_dialog (GetHWND ());
}

long
ExpressPackageSetupPage::OnBack ()
{
  HWND h = GetHWND ();
  save_dialog (h);
  return IDD_SPLASH;
}

long
ExpressPackageSetupPage::OnNext()
{
    HWND h = GetHWND ();
    save_dialog (h);

    Progress.SetActivateTask (WM_APP_PREREQ_CHECK);
    return IDD_INSTATUS;
}

long
ExpressPackageSetupPage::OnUnattended ()
{
  return -1;
}

bool
ExpressPackageSetupPage::OnMessageApp (UINT uMsg, WPARAM wParam, LPARAM lParam)
{
  switch (uMsg)
    {
    case WM_APP_UNATTENDED_FINISH:
      {
	GetOwner ()->PressButton(PSBTN_FINISH);
	break;
      }
    default:
      {
	// Not handled
	return false;
      }
    }

  return true;
}
