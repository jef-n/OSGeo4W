/*
 * Copyright (c) 2000, 2001 Red Hat, Inc.
 *
 *     This program is free software; you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation; either version 2 of the License, or
 *     (at your option) any later version.
 *
 *     A copy of the GNU General Public License can be found at
 *     http://www.gnu.org/
 *
 * Written by DJ Delorie <dj@cygnus.com>
 *
 */

/* The purpose of this file is to manage all the desktop setup, such
   as start menu, batch files, desktop icons, and shortcuts.  Note
   that unlike other do_* functions, this one is called directly from
   install.cc */

#if 0
static const char *cvsid =
  "\n%%% $Id: desktop.cc,v 2.48 2007/05/04 21:56:53 igor Exp $\n";
#endif

#include "win32.h"
#include <shlobj.h>
#include "desktop.h"
#include "propsheet.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "ini.h"
#include "resource.h"
#include "msg.h"
#include "state.h"
#include "dialog.h"
#include "mount.h"
#include "mklink2.h"
#include "package_db.h"
#include "package_meta.h"
#include "package_version.h"
#include "filemanip.h"
#include "io_stream.h"
#include "getopt++/BoolOption.h"
#include "PackageSpecification.h"
#include "LogFile.h"

#define OSGEO4W_SHELL "OSGeo4W Shell"

BoolOption NoShortcutsOption (false, 'n', "no-shortcuts", "Disable creation of desktop and start menu shortcuts");
BoolOption NoStartMenuOption (false, 'N', "no-startmenu", "Disable creation of start menu shortcut");
BoolOption NoDesktopOption (false, 'd', "no-desktop", "Disable creation of desktop shortcut");

/* Lines starting with '@' are conditionals - include 'N' for NT,
   '5' for Win95, '8' for Win98, '*' for all, like this:
	echo foo
	@N8
	echo NT or 98
	@*
   */

static std::string batname;
static std::string iconname;

static ControlAdjuster::ControlInfo DesktopControlsInfo[] = {
  {IDC_DESKTOP_SEPARATOR, 	CP_STRETCH, CP_BOTTOM},
  {IDC_STATUS, 			CP_LEFT, CP_BOTTOM},
  {IDC_STATUS_HEADER, 		CP_LEFT, CP_BOTTOM},
  {0, CP_LEFT, CP_TOP}
};

DesktopSetupPage::DesktopSetupPage ()
{
  sizeProcessor.AddControlInfo (DesktopControlsInfo);
}

void
get_startmenu(std::string &target)
{
  char path[MAX_PATH];
  LPITEMIDLIST id;
  int issystem = (root_scope == IDC_ROOT_SYSTEM) ? 1 : 0;
  SHGetSpecialFolderLocation (NULL,
			      issystem ? CSIDL_COMMON_PROGRAMS :
			      CSIDL_PROGRAMS, &id);
  SHGetPathFromIDList (id, path);
  // following lines added because it appears Win95 does not use common programs
  // unless it comes into play when multiple users for Win95 is enabled
  msg ("Program directory for program link: %s\n", path);
  if (strlen (path) == 0)
    {
      SHGetSpecialFolderLocation (NULL, CSIDL_PROGRAMS, &id);
      SHGetPathFromIDList (id, path);
      msg ("Program directory for program link changed to: %s\n", path);
    }
  // end of Win95 addition

  target = std::string(path) + "/" + menu_name;
}

void
get_desktop(std::string &target)
{
  char path[MAX_PATH];

  LPITEMIDLIST id;
  int issystem = (root_scope == IDC_ROOT_SYSTEM) ? 1 : 0;
  SHGetSpecialFolderLocation (NULL,
			      issystem ? CSIDL_COMMON_DESKTOPDIRECTORY :
			      CSIDL_DESKTOPDIRECTORY, &id);
  SHGetPathFromIDList (id, path);
  // following lines added because it appears Win95 does not use common programs
  // unless it comes into play when multiple users for Win95 is enabled
  msg ("Directory for desktop link: %s\n", path);
  if (strlen (path) == 0)
    {
      SHGetSpecialFolderLocation (NULL, CSIDL_DESKTOP, &id);
      SHGetPathFromIDList (id, path);
      msg ("Program directory for program link changed to: %s\n", path);
    }
  // end of Win95 addition
  
  target = std::string(path) + "/" + menu_name;
}

static void
make_link (const std::string& linkpath,
           const std::string& title,
           const std::string& target,
           const std::string& arg)
{
  std::string fname = linkpath + "/" + title + ".lnk";

  if (_access (fname.c_str(), 0) == 0)
    return;			/* already exists */

  msg ("make_link %s, %s, %s\n",
       fname.c_str(), title.c_str(), target.c_str());

  io_stream::mkpath_p (PATH_TO_FILE, std::string ("file://") + fname);

  std::string exepath;
  std::string argbuf;

  exepath = target;
  argbuf = arg;

  msg ("make_link_2 (%s, %s, %s, %s)\n",
       exepath.c_str(), argbuf.c_str(),
       iconname.c_str(), fname.c_str());
  make_link_2 (exepath.c_str(), argbuf.c_str(),
	       iconname.c_str(), fname.c_str());
}

static void
start_menu (const std::string& title, const std::string& target,
	    const std::string& arg = "")
{
  std::string path;
  get_startmenu(path);
  make_link (path, title, target, arg);
}

static void
desktop_icon (const std::string& title, const std::string& target,
	      const std::string& arg = "")
{
  std::string path;
  get_desktop(path);
  make_link (path, title, target, arg);
}

static void
check_if_enable_next (HWND h)
{
  EnableWindow (GetDlgItem (h, IDOK), 1);
}

extern LogFile * theLog;

static void
set_status (HWND h)
{
  char buf[1000], fmt[1000];
  if (LoadString (hinstance, exit_msg, fmt, sizeof fmt) > 0)
    {
      snprintf (buf, sizeof buf, fmt, backslash(theLog->getFileName(LOG_BABBLE)).c_str());
      eset(h, IDC_STATUS, buf);
    }
}

static char *header_string = NULL;
static char *message_string = NULL;
static void
load_dialog (HWND h)
{
  if (source == IDC_SOURCE_DOWNLOAD)
    {
      // Don't need the checkboxes
      if (header_string == NULL)
        header_string = eget (h, IDC_STATIC_HEADER_TITLE, header_string);
      if (message_string == NULL) 
        message_string = eget (h, IDC_STATIC_HEADER, message_string);
      eset (h, IDC_STATIC_HEADER_TITLE, "Installation complete");
      eset (h, IDC_STATIC_HEADER, "Shows installation status in download-only mode.");
    }
  else
    {
      if (header_string != NULL)
        eset (h, IDC_STATIC_HEADER_TITLE, header_string);
      if (message_string != NULL)
        eset (h, IDC_STATIC_HEADER, message_string);
    }
  check_if_enable_next (h);
  set_status (h);
}

static int
check_desktop (const std::string title, const std::string target)
{
  std::string desktop;
  get_desktop(desktop);

  std::string fname = desktop + "/" + title + ".lnk";

  if (_access (fname.c_str(), 0) == 0)
    return 0;			/* already exists */

  fname = desktop + "/" + title + ".pif";	/* check for a pif as well */

  if (_access (fname.c_str(), 0) == 0)
    return 0;			/* already exists */

  return IDC_ROOT_DESKTOP;
}

static int
check_startmenu (const std::string title, const std::string target)
{
  char path[MAX_PATH];
  LPITEMIDLIST id;
  int issystem = (root_scope == IDC_ROOT_SYSTEM) ? 1 : 0;
  SHGetSpecialFolderLocation (NULL,
			      issystem ? CSIDL_COMMON_PROGRAMS :
			      CSIDL_PROGRAMS, &id);
  SHGetPathFromIDList (id, path);
  // following lines added because it appears Win95 does not use common programs
  // unless it comes into play when multiple users for Win95 is enabled
  msg ("Program directory for program link: %s", path);
  if (strlen (path) == 0)
    {
      SHGetSpecialFolderLocation (NULL, CSIDL_PROGRAMS, &id);
      SHGetPathFromIDList (id, path);
      msg ("Program directory for program link changed to: %s", path);
    }
  // end of Win95 addition
  strcat (path, "/OSGeo4W");
  std::string fname = std::string(path) + "/" + title + ".lnk";

  if (_access (fname.c_str(), 0) == 0)
    return 0;			/* already exists */

  fname = std::string(path) + "/" + title + ".pif";	/* check for a pif as well */

  if (_access (fname.c_str(), 0) == 0)
    return 0;			/* already exists */

  return IDC_ROOT_MENU;
}

bool
DesktopSetupPage::Create ()
{
  return PropertyPage::Create (IDD_DESKTOP);
}

void
DesktopSetupPage::OnInit ()
{
  SetDlgItemFont(IDC_STATUS_HEADER, "MS Shell Dlg", 8, FW_BOLD);

  EnableWindow ( GetDlgItem (IDC_ROOT_SYSTEM), is_elevated() );
}

void
DesktopSetupPage::OnActivate ()
{
  if (NoShortcutsOption || source == IDC_SOURCE_DOWNLOAD) 
    {
      root_desktop = root_menu = 0;
    }
  else
    {
      if (NoStartMenuOption) 
	{
	  root_menu = 0;
	}
      else
	{
	  root_menu = check_startmenu (OSGEO4W_SHELL, backslash (cygpath ("/OSGeo4W.bat")));
	}

      if (NoDesktopOption) 
	{
	  root_desktop = 0;
	}
      else
	{
	  root_desktop = check_desktop (OSGEO4W_SHELL, backslash (cygpath ("/OSGeo4W.bat")));
	}
    }

  load_dialog (GetHWND ());
}

long
DesktopSetupPage::OnBack ()
{
  if( express_mode_option )
      return (long)express_mode_option;
  else
      return IDD_CHOOSE;
}

bool
DesktopSetupPage::OnFinish ()
{
  return true;
}

long 
DesktopSetupPage::OnUnattended ()
{
  Window::PostMessageNow (WM_APP_UNATTENDED_FINISH);
  // GetOwner ()->PressButton(PSBTN_FINISH);
  return -1;
}

bool
DesktopSetupPage::OnMessageApp (UINT uMsg, WPARAM wParam, LPARAM lParam)
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
