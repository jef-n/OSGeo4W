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

#ifndef SETUP_THREEBAR_H
#define SETUP_THREEBAR_H

// This is the header for the ThreeBarProgressPage class.  It is a fairly generic
// progress indicator property page with three progress bars.


#include "win32.h"
#include "proppage.h"

#define WM_APP_START_DOWNLOAD              WM_APP+0
#define WM_APP_DOWNLOAD_THREAD_COMPLETE    WM_APP+1
#define WM_APP_START_INSTALL               WM_APP+2
#define WM_APP_INSTALL_THREAD_COMPLETE     WM_APP+3
#define WM_APP_START_SITE_INFO_DOWNLOAD    WM_APP+4
#define WM_APP_SITE_INFO_DOWNLOAD_COMPLETE WM_APP+5
#define WM_APP_START_SETUP_INI_DOWNLOAD    WM_APP+6
#define WM_APP_SETUP_INI_DOWNLOAD_COMPLETE WM_APP+7
#define WM_APP_UNATTENDED_FINISH           WM_APP+8
#define WM_APP_START_POSTINSTALL           WM_APP+9
#define WM_APP_POSTINSTALL_THREAD_COMPLETE WM_APP+10
#define WM_APP_PREREQ_CHECK                WM_APP+11
#define WM_APP_PREREQ_CHECK_THREAD_COMPLETE WM_APP+12
#define WM_APP_START_LICENSE_FILE_DOWNLOAD WM_APP+13
#define WM_APP_LICENSE_FILE_DOWNLOAD_COMPLETE WM_APP+14

class ThreeBarProgressPage:public PropertyPage
{
  HWND ins_action;
  HWND ins_pkgname;
  HWND ins_filename;
  HWND ins_pprogress;
  HWND ins_iprogress;
  HWND ins_diskfull;
  HWND ins_bl_package;
  HWND ins_bl_total;
  HWND ins_bl_disk;

  int task;

  void EnableSingleBar (bool enable = true);

public:
  ThreeBarProgressPage ();
  virtual ~ThreeBarProgressPage() {}
  bool Create ();

  virtual void OnInit ();
  virtual void OnActivate ();
  virtual bool OnMessageApp (UINT uMsg, WPARAM wParam, LPARAM lParam);
  virtual long OnUnattended () { return -1; }

  void SetText1 (const TCHAR * t);
  void SetText2 (const TCHAR * t);
  void SetText3 (const TCHAR * t);
  void SetText4 (const TCHAR * t);

  void SetBar1 (size_t progress, size_t max = 100);
  void SetBar2 (size_t progress, size_t max = 100);
  void SetBar3 (size_t progress, size_t max = 100);

  void SetActivateTask (int t) { task = t; }
};


#endif /* SETUP_THREEBAR_H */
