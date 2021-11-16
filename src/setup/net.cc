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

/* The purpose of this file is to get the network configuration
   information from the user. */

#include "net.h"

#include "LogSingleton.h"

#include "win32.h"
#include <stdio.h>
#include <stdlib.h>
#include <sstream>
#include "dialog.h"
#include "resource.h"
#include "netio.h"
#include "msg.h"

#include "getopt++/StringOption.h"
#include "propsheet.h"
#include "threebar.h"
#include "ConnectionSetting.h"
extern ThreeBarProgressPage Progress;

static StringOption ProxyOption ("", 'p', "proxy", "HTTP/FTP proxy (host:port)", false);

static int rb[] = { IDC_NET_PRECONFIG, IDC_NET_DIRECT, IDC_NET_PROXY, 0 };
static bool doing_loading = false;

void
NetPage::CheckIfEnableNext ()
{
  int e = 0, p = 0;
  DWORD ButtonFlags = PSWIZB_BACK;

  if (NetIO::net_method == IDC_NET_PRECONFIG ||
      NetIO::net_method == IDC_NET_DIRECT)
    e = 1;
  else if (NetIO::net_method == IDC_NET_PROXY)
    {
      p = 1;
      if (NetIO::net_proxy_host && NetIO::net_proxy_port)
        e = 1;
    }

  if (e)
    {
      // There's something in the proxy and port boxes, enable "Next".
      ButtonFlags |= PSWIZB_NEXT;
    }

  GetOwner ()->SetButtons (ButtonFlags);

  EnableWindow (GetDlgItem (IDC_PROXY_HOST), p);
  EnableWindow (GetDlgItem (IDC_PROXY_PORT), p);
}

static void
load_dialog (HWND h)
{
  doing_loading = true;

  rbset (h, rb, NetIO::net_method);
  eset (h, IDC_PROXY_HOST, NetIO::net_proxy_host);
  if (NetIO::net_proxy_port == 0)
    NetIO::net_proxy_port = 80;
  eset (h, IDC_PROXY_PORT, NetIO::net_proxy_port);

  doing_loading = false;
}

static void
save_dialog (HWND h)
{
  // Without this, save_dialog() is called in the middle of load_dialog()
  // because the window receives a message when the value changes.  If this
  // happens, save_dialog() tries to read the values of the fields, resulting
  // in the net_proxy_port being reset to zero - this is the cause of the
  // preference not sticking.
  if (doing_loading)
    return;

  NetIO::net_method = rbget (h, rb);
  NetIO::net_proxy_host = eget (h, IDC_PROXY_HOST, NetIO::net_proxy_host);
  NetIO::net_proxy_port = eget (h, IDC_PROXY_PORT);
}

bool
NetPage::Create ()
{
  return PropertyPage::Create (IDD_NET);
}

void
NetPage::OnInit ()
{
  HWND h = GetHWND ();
  std::string proxyString (ProxyOption);

  if (!NetIO::net_method)
    NetIO::net_method = IDC_NET_PRECONFIG;

  if (proxyString.size ())
  {
    size_t pos = proxyString.find_last_of (':');
    if ((pos > 0) && (pos < (proxyString.size () - 1)))
    {
      NetIO::net_method = IDC_NET_PROXY;
      NetIO::net_proxy_host = strdup (proxyString.substr (0, pos).c_str ());
      std::string portString = proxyString.substr (pos + 1, proxyString.size () - (pos + 1));
      std::istringstream iss (portString, std::istringstream::in);
      iss >> NetIO::net_proxy_port;
    }
  }

  load_dialog (h);
  CheckIfEnableNext();

  // Check to see if any radio buttons are selected. If not, select a default.
  if (SendMessage (GetDlgItem (IDC_NET_DIRECT), BM_GETCHECK, 0, 0) != BST_CHECKED
      && SendMessage (GetDlgItem (IDC_NET_PROXY), BM_GETCHECK, 0, 0) != BST_CHECKED)
    SendMessage (GetDlgItem (IDC_NET_PRECONFIG), BM_CLICK, 0, 0);
}

long
NetPage::OnNext ()
{
  save_dialog (GetHWND ());

  log (LOG_PLAIN) << "net: " << NetIO::net_method_name() << endLog;

  Progress.SetActivateTask (WM_APP_START_SITE_INFO_DOWNLOAD);
  return IDD_INSTATUS;
}

long
NetPage::OnUnattended()
{
  return OnNext ();
}

long
NetPage::OnBack ()
{
  save_dialog (GetHWND ());
  return 0;
}

bool
NetPage::OnMessageCmd (int id, HWND hwndctl, UINT code)
{
  switch (id)
    {
    case IDC_NET_PRECONFIG:
    case IDC_NET_DIRECT:
    case IDC_NET_PROXY:
    case IDC_PROXY_HOST:
    case IDC_PROXY_PORT:
      save_dialog (GetHWND());
      CheckIfEnableNext ();
      break;

    default:
      // Wasn't recognized or handled.
      return false;
    }

  // Was handled since we never got to default above.
  return true;
}
