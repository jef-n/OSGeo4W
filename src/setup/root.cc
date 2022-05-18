/*
 * Copyright (c) 2000, Red Hat, Inc.
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

/* The purpose of this file is to ask the user where they want the
   root of the installation to be, and to ask whether the user prefers
   text or binary mounts. */

#include "root.h"

#include "LogSingleton.h"

#include "win32.h"
#include <shlobj.h>
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>

#include "ini.h"
#include "dialog.h"
#include "resource.h"
#include "state.h"
#include "msg.h"
#include "package_db.h"
#include "mount.h"
#include "desktop.h"

#include "getopt++/BoolOption.h"

using namespace std;

static ControlAdjuster::ControlInfo RootControlsInfo[] = {
  { IDC_ROOTDIR_GRP,              CP_STRETCH,           CP_TOP      },
  { IDC_ROOT_DIR,                 CP_STRETCH,           CP_TOP      },
  { IDC_ROOT_BROWSE,              CP_RIGHT,             CP_TOP      },

  { IDC_INSTALLFOR_GRP,           CP_STRETCH_LEFTHALF,  CP_STRETCH  },
  { IDC_ROOT_SYSTEM,              CP_LEFT,              CP_TOP      },
  { IDC_ALLUSERS_TEXT,            CP_STRETCH_LEFTHALF,  CP_TOP      },
  { IDC_ROOT_USER,                CP_LEFT,              CP_TOP      },
  { IDC_JUSTME_TEXT,              CP_STRETCH_LEFTHALF,  CP_TOP      },

  { IDC_ROOT_DESKTOP,             CP_RIGHT,             CP_TOP      },
  { IDC_ROOT_MENU,                CP_RIGHT,             CP_TOP      },

  {0, CP_LEFT, CP_TOP}
};

static int su[] = { IDC_ROOT_SYSTEM, IDC_ROOT_USER, 0 };
static std::string root_dir;

static void
check_if_enable_next (HWND h)
{
  EnableWindow (GetDlgItem (h, IDOK), root_dir.size() && root_scope );
}

static inline void
GetDlgItemRect (HWND h, int item, LPRECT r)
{
  GetWindowRect (GetDlgItem (h, item), r);
  MapWindowPoints (HWND_DESKTOP, h, (LPPOINT) r, 2);
}

static inline void
SetDlgItemRect (HWND h, int item, LPRECT r)
{
  MoveWindow (GetDlgItem (h, item), r->left, r->top,
	      r->right - r->left, r->bottom - r->top, TRUE);
}

static bool loading = true;

static void
load_dialog (HWND h)
{
  int elevated = is_elevated();

  if( !elevated && root_scope == IDC_ROOT_SYSTEM )
      root_scope = IDC_ROOT_USER;

  rbset (h, su, root_scope);

  EnableWindow( GetDlgItem( h, IDC_ROOT_SYSTEM ), elevated );

  CheckDlgButton (h, IDC_ROOT_DESKTOP, (!NoShortcutsOption && (DesktopOption || root_desktop)) ? BST_CHECKED : BST_UNCHECKED );
  CheckDlgButton (h, IDC_ROOT_MENU,    (!NoShortcutsOption && !NoStartMenuOption && root_menu) ? BST_CHECKED : BST_UNCHECKED );

  loading = true;
  eset (h, IDC_ROOT_DIR, root_dir );
  loading = false;


  check_if_enable_next (h);
}

static void
save_dialog (HWND h)
{
  root_scope = rbget (h, su);
  root_desktop = IsDlgButtonChecked( h, IDC_ROOT_DESKTOP ) == BST_CHECKED;
  root_menu = IsDlgButtonChecked( h, IDC_ROOT_MENU ) == BST_CHECKED;

  root_dir = egetString (h, IDC_ROOT_DIR);
}

static int CALLBACK
browse_cb (HWND h, UINT msg, LPARAM lp, LPARAM data)
{
  switch (msg)
    {
    case BFFM_INITIALIZED:
      if (root_dir.size())
        SendMessage (h, BFFM_SETSELECTION, TRUE, (LPARAM) root_dir.c_str());
      break;
    }
  return 0;
}

static void
browse (HWND h)
{
  BROWSEINFO bi;
  CHAR name[MAX_PATH];
  LPITEMIDLIST pidl;
  memset (&bi, 0, sizeof bi);
  bi.hwndOwner = h;
  bi.pszDisplayName = name;
  bi.lpszTitle = "Select an installation root directory";
  bi.ulFlags = BIF_RETURNONLYFSDIRS;
  bi.lpfn = browse_cb;
  pidl = SHBrowseForFolder (&bi);
  if (pidl)
    {
      if (SHGetPathFromIDList (pidl, name))
        eset (h, IDC_ROOT_DIR, name);
    }
}

static int
directory_is_absolute ()
{
  std::string r = root_dir.c_str();
  if (isalpha (r[0]) && r[1] == ':' && isdirsep(r[2]))
    {
      return 1;
    }
  return 0;
}

static int
directory_is_rootdir ()
{
  for (const char *c = root_dir.c_str(); *c; c++)
    if (isdirsep (c[0]) && c[1] && !isdirsep (c[1]))
      return 0;
  return 1;
}

static int
directory_has_spaces ()
{
  if ( root_dir.find(' ') != std::string::npos)
    return 1;
  return 0;
}

bool
RootPage::OnMessageCmd (int id, HWND hwndctl, UINT code)
{
  switch (id)
    {
    case IDC_ROOT_DIR:
    case IDC_ROOT_SYSTEM:
    case IDC_ROOT_USER:
      check_if_enable_next (GetHWND ());
      break;

    case IDC_ROOT_BROWSE:
      browse (GetHWND ());
      break;
    default:
      return false;
    }
  return true;
}

RootPage::RootPage ()
{
  sizeProcessor.AddControlInfo (RootControlsInfo);
  root_scope = is_elevated() ? IDC_ROOT_SYSTEM : IDC_ROOT_USER;
}

bool
RootPage::Create ()
{
  return PropertyPage::Create (IDD_ROOT);
}

void
RootPage::OnInit ()
{
  root_dir = get_root_dir();
  load_dialog (GetHWND ());
}

bool
RootPage::wantsActivation() const
{
  return source != IDC_SOURCE_DOWNLOAD;
}

long
RootPage::OnNext ()
{
  HWND h = GetHWND ();

  save_dialog (h);

  bool changed = root_dir != get_root_dir();
  if ( changed )
  set_root_dir ( root_dir );

  if (!directory_is_absolute ())
    {
      note (h, IDS_ROOT_ABSOLUTE);
      return -1;
    }
  else if (directory_is_rootdir () && (IDNO == yesno (h, IDS_ROOT_SLASH)))
    return -1;
  else if (directory_has_spaces () && (IDNO == yesno (h, IDS_ROOT_SPACE)))
    return -1;

  log (LOG_PLAIN) << "root: " << get_root_dir () << endLog;

  return 0;
}

long
RootPage::OnBack ()
{
  save_dialog ( GetHWND () );
  return 0;
}

long
RootPage::OnUnattended ()
{
  return OnNext();
}
