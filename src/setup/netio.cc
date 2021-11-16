/*
 * Copyright (c) 2000, 2001, Red Hat, Inc.
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

/* The purpose of this file is to coordinate the various access
   methods known to setup.  To add a new method, create a pair of
   nio-*.[ch] files and add the logic to NetIO::open here */

#include "netio.h"

#include "LogFile.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <shlwapi.h>

#include "resource.h"
#include "state.h"
#include "msg.h"
#include "nio-ie5.h"
#include "dialog.h"

int NetIO::net_method;
char *NetIO::net_proxy_host;
int NetIO::net_proxy_port;

char *NetIO::net_user;
char *NetIO::net_passwd;
char *NetIO::net_proxy_user;
char *NetIO::net_proxy_passwd;
char *NetIO::net_ftp_user;
char *NetIO::net_ftp_passwd;

NetIO *
NetIO::open (char const *url, bool cachable)
{
  NetIO *rv = 0;
  std::string file_url;

  enum
  { http, https, ftp, ftps, file }
  proto;
  if (strncmp (url, "http://", 7) == 0)
    proto = http;
  else if (strncmp (url, "https://", 8) == 0)
    proto = https;
  else if (strncmp (url, "ftp://", 6) == 0)
    proto = ftp;
  else if (strncmp (url, "ftps://", 7) == 0)
    proto = ftps;
  else if (strncmp (url, "file://", 7) == 0)
    {
      proto = file;

      // WinInet expects a 'legacy' file:// URL
      // (i.e. a windows path with "file://" prepended)
      // https://blogs.msdn.microsoft.com/freeassociations/2005/05/19/the-bizarre-and-unhappy-story-of-file-urls/
      char path[MAX_PATH];
      DWORD len = MAX_PATH;
      if (S_OK == PathCreateFromUrl(url, path, &len, 0))
        {
          file_url = std::string("file://") + path;
          url = file_url.c_str();
        }
    }
  else
    // treat everything else as a windows path
    {
      proto = file;
      file_url = std::string("file://") + url;
      url = file_url.c_str();
    }

  rv = new NetIO_IE5 (url, proto == file ? false : cachable);

  if (rv && !rv->ok ())
    {
      delete rv;
      return 0;
    }

  return rv;
}


static char **user, **passwd;
static int loading = 0;

static void
check_if_enable_ok (HWND h)
{
  int e = 0;
  if (*user)
    e = 1;
  EnableWindow (GetDlgItem (h, IDOK), e);
}

static void
load_dialog (HWND h)
{
  loading = 1;
  eset (h, IDC_NET_USER, *user);
  eset (h, IDC_NET_PASSWD, *passwd);
  check_if_enable_ok (h);
  loading = 0;
}

static void
save_dialog (HWND h)
{
  *user = eget (h, IDC_NET_USER, *user);
  *passwd = eget (h, IDC_NET_PASSWD, *passwd);
  if (! *passwd) {
    *passwd = new char[1];
    (*passwd)[0] = '\0';
  }
}

static BOOL
auth_cmd (HWND h, int id, HWND hwndctl, UINT code)
{
  switch (id)
    {

    case IDC_NET_USER:
    case IDC_NET_PASSWD:
      if (code == EN_CHANGE && !loading)
	{
	  save_dialog (h);
	  check_if_enable_ok (h);
	}
      break;

    case IDOK:
      save_dialog (h);
      EndDialog (h, 0);
      break;

    case IDCANCEL:
      EndDialog (h, 1);
      LogSingleton::GetInstance().exit (1);
      break;
    }
  return 0;
}

static INT_PTR CALLBACK
auth_proc (HWND h, UINT message, WPARAM wParam, LPARAM lParam)
{
  switch (message)
    {
    case WM_INITDIALOG:
      load_dialog (h);
      return FALSE;
    case WM_COMMAND:
      auth_cmd (h, LOWORD(wParam), (HWND)lParam, HIWORD(wParam));
      return 0;
    }
  return FALSE;
}

static INT_PTR
auth_common (HINSTANCE h, int id, HWND owner)
{
  return DialogBox (h, MAKEINTRESOURCE (id), owner, auth_proc);
}

INT_PTR
NetIO::get_auth (HWND owner)
{
  user = &net_user;
  passwd = &net_passwd;
  return auth_common (hinstance, IDD_NET_AUTH, owner);
}

INT_PTR
NetIO::get_proxy_auth (HWND owner)
{
  user = &net_proxy_user;
  passwd = &net_proxy_passwd;
  return auth_common (hinstance, IDD_PROXY_AUTH, owner);
}

INT_PTR
NetIO::get_ftp_auth (HWND owner)
{
  if (net_ftp_user)
    {
      delete[] net_ftp_user;
      net_ftp_user = NULL;
    }
  if (net_ftp_passwd)
    {
      delete[] net_ftp_passwd;
      net_ftp_passwd = NULL;
    }
  user = &net_ftp_user;
  passwd = &net_ftp_passwd;
  return auth_common (hinstance, IDD_FTP_AUTH, owner);
}

const char *
NetIO::net_method_name ()
{
  switch (net_method)
    {
    case IDC_NET_PRECONFIG:
      return "Preconfig";
    case IDC_NET_DIRECT:
      return "Direct";
    case IDC_NET_PROXY:
      return "Proxy";
    default:
      return "Unknown";
    }
}
