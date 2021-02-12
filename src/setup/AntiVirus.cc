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

#include "AntiVirus.h"

#include "getopt++/BoolOption.h"

#include "LogSingleton.h"

#include "win32.h"
#include <stdio.h>
#include "dialog.h"
#include "resource.h"
#include "state.h"
#include "msg.h"
#include "package_db.h"


/* XXX: Split this into observer and model classes */
  
/* Default is to leave well enough alone */
static BoolOption DisableVirusOption (false, 'b', "disable-buggy-antivirus", "Disable known or suspected buggy anti virus software packages during execution.");

static bool KnownAVIsPresent = false;
static bool AVRunning = true;
static SC_HANDLE SCM = NULL;
static SC_HANDLE McAfeeService = NULL;
static void detect();

static int rb[] =
{ IDC_DISABLE_AV, IDC_LEAVE_AV, 0};

static int disableAV = IDC_LEAVE_AV;

static void
load_dialog (HWND h)
{
  rbset (h, rb, disableAV);
}

static void
save_dialog (HWND h)
{
  disableAV = rbget (h, rb);
}

static BOOL
dialog_cmd (HWND h, int id, HWND hwndctl, UINT code)
{
  switch (id)
    {

    case IDC_DISABLE_AV:
    case IDC_LEAVE_AV:
      save_dialog (h);
      break;

    default:
      break;
    }
  return 0;
}

bool
AntiVirusPage::Create ()
{
    detect();
    return PropertyPage::Create (NULL, dialog_cmd, IDD_VIRUS);
}

void
AntiVirusPage::OnActivate ()
{
  load_dialog (GetHWND ());
  // Check to see if any radio buttons are selected. If not, select a default.
  if ((!SendMessage
       (GetDlgItem (IDC_DISABLE_AV), BM_GETCHECK, 0,
	0) == BST_CHECKED)
      && (!SendMessage (GetDlgItem (IDC_LEAVE_AV), BM_GETCHECK, 0, 0)
	  == BST_CHECKED))
    {
      SendMessage (GetDlgItem (IDC_LEAVE_AV), BM_SETCHECK,
		   BST_CHECKED, 0);
    }
}

bool
AntiVirusPage::wantsActivation() const
{
  // Check if there's an antivirus scanner to be disabled.
  if(!KnownAVIsPresent)
  {
    // Nope, skip this page by "not accepting" activation.
    return false;
  }

  return true;
}

long
AntiVirusPage::OnNext ()
{
  HWND h = GetHWND ();

  save_dialog (h);
  /* if disable, do so now */
  return 0;
}

long
AntiVirusPage::OnBack ()
{
  save_dialog (GetHWND ());
  return 0;
}

void
AntiVirusPage::OnDeactivate ()
{
  if (!KnownAVIsPresent)
	return;
  if (disableAV == IDC_LEAVE_AV)
      return;

  SERVICE_STATUS status;
  if (!ControlService (McAfeeService, SERVICE_CONTROL_STOP, &status) &&
      GetLastError() != ERROR_SERVICE_NOT_ACTIVE)
    {
      log (LOG_PLAIN) << "Could not stop McAfee service, disabled AV logic"
        << endLog;
      disableAV = IDC_LEAVE_AV;
      return;
    }
	
  AVRunning = false;
  log (LOG_PLAIN) << "Disabled Anti Virus software" << endLog;
}

long
AntiVirusPage::OnUnattended ()
{
  if (!KnownAVIsPresent)
    return OnNext();
  if ((bool)DisableVirusOption)
    disableAV = IDC_DISABLE_AV;
  else
    disableAV = IDC_LEAVE_AV;

  return OnNext();
}

void
detect ()
{
    if (!IsWindowsNT() || safe_mode)
	return;

    // TODO: trim the access rights down 
    SCM = OpenSCManager (NULL, NULL, SC_MANAGER_ALL_ACCESS);

    if (!SCM) {
	log (LOG_PLAIN) << "Could not open Service control manager" << endLog;
	return;
    }
    
    /* in future, factor this to a routine to find service foo (ie norton, older
       mcafee etc 
       */
    McAfeeService = OpenService (SCM, "AvSynMgr", 
	SERVICE_QUERY_STATUS| SERVICE_STOP| SERVICE_START);

    if (!McAfeeService) {
	log (LOG_PLAIN) << "Could not open service McShield for query, start and stop. McAfee may not be installed, or we don't have access." << endLog;
	CloseServiceHandle(SCM);
	return;
    }

    SERVICE_STATUS status;

    if (!QueryServiceStatus (McAfeeService, &status))
      {
	CloseServiceHandle(SCM);
	CloseServiceHandle(McAfeeService);
	log (LOG_PLAIN) << "Couldn't determine status of McAfee service."
          << endLog;
	return;
      }

    if (status.dwCurrentState == SERVICE_STOPPED ||
	status.dwCurrentState == SERVICE_STOP_PENDING) 
      {
	CloseServiceHandle(SCM);
	CloseServiceHandle(McAfeeService);
	log (LOG_PLAIN) << "Mcafee is already stopped, nothing to see here"
          << endLog;
      }
    
    log (LOG_PLAIN) << "Found McAfee anti virus program" << endLog;
    KnownAVIsPresent = true;
}

bool
AntiVirus::Show()
{
    return KnownAVIsPresent;
}

void
AntiVirus::AtExit()
{
    if (!KnownAVIsPresent)
	return;
    if (disableAV == IDC_LEAVE_AV)
	return;
    if (AVRunning == true)
	return;

    if (!StartService(McAfeeService, 0, NULL))
        {
	  log (LOG_PLAIN) << "Could not start McAfee service again, disabled AV logic" << endLog;
	  disableAV = IDC_LEAVE_AV;
	  return;
	}

    log (LOG_PLAIN) << "Enabled Anti Virus software" << endLog;  
    
    AVRunning = true;
	
}
