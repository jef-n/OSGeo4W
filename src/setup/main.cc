/*
 * Copyright (c) 2000, Red Hat, Inc.
 * Copyright (c) 2003, Robert Collins <rbtcollins@hotmail.com>
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
 *            Robert Collins <rbtcollins@hotmail.com>
 *
 *
 */

/* OK, here's how this works.  Each of the steps needed for install -
   dialogs, downloads, installs - are in their own files and have some
   "do_*" function (prototype in dialog.h) and a resource id (IDD_* or
   IDD_S_* in resource.h) for that step.  Each step is responsible for
   selecting the next step!  See the NEXT macro in dialog.h.  Note
   that the IDD_S_* ids are fake; those are for steps that don't
   really have a controlling dialog (some have progress dialogs, but
   those don't count, although they could).  Replace the IDD_S_* with
   IDD_* if you create a real dialog for those steps. */

#if 0
static const char *cvsid =
  "\n%%% $Id: main.cc,v 2.73 2013/06/22 20:02:01 cgf Exp $\n";
#endif

#undef _WIN32_WINNT
#define _WIN32_WINNT 0x0501
#include "win32.h"
#include <commctrl.h>
#include "shlobj.h"

#include <stdio.h>
#include <stdlib.h>
#include "resource.h"
#include "dialog.h"
#include "state.h"
#include "msg.h"
#include "find.h"
#include "mount.h"
#include "LogFile.h"
#include "setup_version.h"

#include "proppage.h"
#include "propsheet.h"

// Page class headers
#include "splash.h"
#include "express_package.h"
#include "AntiVirus.h"
#include "source.h"
#include "root.h"
#include "localdir.h"
#include "net.h"
#include "site.h"
#include "choose.h"
#include "prereq.h"
#include "threebar.h"
#include "desktop.h"
#include "postinstallresults.h"

#include "getopt++/GetOption.h"
#include "getopt++/BoolOption.h"
#include "getopt++/StringOption.h"

#include "Exception.h"
#include <stdexcept>

#include "UserSettings.h"
#include "SourceSetting.h"
#include "ConnectionSetting.h"

#include <wincon.h>
#include <fstream>

bool is_64bit;

using namespace std;

HINSTANCE hinstance;

static StringOption Arch ("", 'a', "arch", "architecture to install (x86_64 or x86)", false);
StringOption RootOption ("", 'R', "root", "Root installation directory", false);
static BoolOption UnattendedOption (false, 'q', "quiet-mode", "Unattended setup mode");
static BoolOption PackageManagerOption (false, 'M', "package-manager", "Semi-attended chooser-only mode");
static BoolOption HelpOption (false, 'h', "help", "print help");
static BOOL (WINAPI *dyn_AttachConsole) (DWORD);

static void inline
set_dynaddr ()
{
  HMODULE hm = LoadLibrary ("kernel32.dll");
  if (!hm)
    return;

  dyn_AttachConsole = (BOOL (WINAPI *)(DWORD)) GetProcAddress (hm, "AttachConsole");
}

static void inline
set_cout ()
{
  HANDLE my_stdout = GetStdHandle (STD_OUTPUT_HANDLE);
  if (my_stdout != INVALID_HANDLE_VALUE && GetFileType (my_stdout) != FILE_TYPE_UNKNOWN)
    return;

  if (dyn_AttachConsole && dyn_AttachConsole ((DWORD) -1))
    {
      ofstream *conout = new ofstream ("conout$");
      cout.rdbuf (conout->rdbuf ());
      cout.flush ();
    }
}

// Other threads talk to these pages, so we need to have it externable.
ThreeBarProgressPage Progress;
PostInstallResultsPage PostInstallResults;

// This is a little ugly, but the decision about where to log occurs
// after the source is set AND the root mount obtained
// so we make the actual logger available to the appropriate routine(s).
LogFile *theLog;

static inline void
main_display (void)
{
  /* nondisplay classes */
  LocalDirSetting localDir;
  SourceSetting SourceSettings;
  ConnectionSetting ConnectionSettings;
  SiteSetting ChosenSites;
  SplashSetting splashSettings;

  SplashPage Splash;
  ExpressPackageSetupPage ExpressPackage;
  AntiVirusPage AntiVirus;
  SourcePage Source;
  RootPage Root;
  LocalDirPage LocalDir;
  NetPage Net;
  SitePage Site;
  ChooserPage Chooser;
  PrereqPage Prereq;
  LicensePage License;
  DesktopSetupPage Desktop;
  PropSheet MainWindow;

  log (LOG_TIMESTAMP) << "Current Directory: " << local_dir << endLog;
  log (LOG_TIMESTAMP) << "Root Directory: " << get_root_dir() << endLog;

  // Initialize common controls
  INITCOMMONCONTROLSEX icce = { sizeof (INITCOMMONCONTROLSEX),
				ICC_WIN95_CLASSES };
  InitCommonControlsEx (&icce);

  if (LoadLibrary ("Riched20.Dll") == NULL)
    {
      MessageBox (NULL, "RichEdit not found!", "Error", MB_ICONERROR);
      return;
    }

  // Initialize COM and ShellLink instance here.  For some reason
  // Windows 7 fails to create the ShellLink instance if this is
  // done later, in the thread which actually creates the shortcuts.
  extern IShellLink *sl;
  CoInitializeEx (NULL, COINIT_APARTMENTTHREADED);
  HRESULT res = CoCreateInstance (CLSID_ShellLink, NULL,
				  CLSCTX_INPROC_SERVER, IID_IShellLink,
				  (LPVOID *) & sl);
  if (res)
    {
      std::string buf = Window::sprintf ("CoCreateInstance failed with error 0x%x.\n"
		    "Setup will not be able to create Cygwin Icons\n"
		    "in the Start Menu or on the Desktop.", (int) res);
      MessageBox (NULL, buf.c_str(), "Cygwin Setup", MB_OK);
    }

  // Init window class lib
  Window::SetAppInstance (hinstance);

  // Create pages
  Splash.Create ();
  AntiVirus.Create ();
  Source.Create ();
  Root.Create ();
  LocalDir.Create ();
  Net.Create ();
  Site.Create ();
  ExpressPackage.Create ();
  Chooser.Create ();
  Prereq.Create ();
  License.Create ();
  Progress.Create ();
  PostInstallResults.Create ();
  Desktop.Create ();

  // Add pages to sheet
  MainWindow.AddPage (&Splash);
  MainWindow.AddPage (&AntiVirus);
  MainWindow.AddPage (&Source);
  MainWindow.AddPage (&Root);
  MainWindow.AddPage (&LocalDir);
  MainWindow.AddPage (&Net);
  MainWindow.AddPage (&Site);
  MainWindow.AddPage (&ExpressPackage);
  MainWindow.AddPage (&Chooser);
  MainWindow.AddPage (&Prereq);
  MainWindow.AddPage (&License);
  MainWindow.AddPage (&Progress);
  MainWindow.AddPage (&PostInstallResults);
  MainWindow.AddPage (&Desktop);

  // Create the PropSheet main window
  MainWindow.Create ();

  // Uninitalize COM
  if (sl)
    sl->Release ();
  CoUninitialize ();
}

int WINAPI
WinMain (HINSTANCE h, HINSTANCE hPrevInstance, LPSTR cmdline, int cmd_show)
{
  hinstance = h;

  msg( "mirror:%s\n", OSGEO4W_MIRROR_URL );

#ifndef _MSC_VER
  int n = strlen( cmdline ) + 1;
  wchar_t *wcmdline = (wchar_t *) calloc( n, sizeof(wchar_t) );
  mbstowcs( wcmdline, cmdline, n );

  LPWSTR *str = CommandLineToArgvW( wcmdline, &__argc );
  __argv = (char **) calloc( __argc, sizeof(char *) );
  for( int i = 0; i < __argc; i++ )
  {
    n = wcslen( str[i] ) + 1;
    __argv[i] = (char *) malloc( n );
    wcstombs( __argv[i], str[i], n );
  }
  LocalFree( str );
#endif

  set_dynaddr ();
  // Make sure the C runtime functions use the same codepage as the GUI
  char locale[12];
  snprintf(locale, sizeof locale, ".%u", GetACP());
  setlocale(LC_ALL, locale);

  try
  {
    char cwd[MAX_PATH];
    GetCurrentDirectory (MAX_PATH, cwd);
    local_dir = std::string (cwd);

    if (!GetOption::GetInstance()->Process (__argc, __argv, NULL))
      exit (1);

    if (!((string) Arch).size ())
      {
#if defined(__x86_64__) || defined(_WIN64)
        is_64bit = true;
#else
        is_64bit = false;
#endif
      }
    else if (((string) Arch).find ("64") != string::npos)
      is_64bit = true;
    else if (((string) Arch).find ("32") != string::npos
	     || ((string) Arch).find ("x86") != string::npos)
      is_64bit = false;
    else
      {
        std::vector<char> buff(80 + ((string) Arch).size ());
        sprintf (buff.data(), "Invalid option for --arch:  \"%s\"", ((string) Arch).c_str ());
        msg("*** %s\n", buff.data());
        MessageBox (NULL, buff.data(), "Invalid option", MB_ICONEXCLAMATION | MB_OK);
        exit (1);
      }

    msg( "Architecture: %s\n", is_64bit ? "64 bit" : "32 bit" );

    std::string root = RootOption;

    if( root.empty() && getenv( "OSGEO4W_ROOT" ) )
      root = getenv( "OSGEO4W_ROOT" );

    if( root.empty() )
      {
        // no explicit root - use a sane default for root,
        // but keep logfiles here as the default might be changed later
        if ( getenv( "SYSTEMDRIVE" ) )
          root = getenv( "SYSTEMDRIVE" );
        else
	      root = "C:";

        root += "\\OSGeo4W" ;
      }
    else
      {
        // explicit root - also put log file there
        local_dir = root;
      }

    set_root_dir( root );

    unattended_mode = PackageManagerOption ? chooseronly : (UnattendedOption ? unattended : attended);

    if (unattended_mode || HelpOption)
      set_cout ();

    LogSingleton::SetInstance (*(theLog = LogFile::createLogFile ()));
    const char *sep = isdirsep (local_dir[local_dir.size () - 1]) ? "" : "\\";
    theLog->setFile (LOG_BABBLE, local_dir + sep + "setup.log.full", false);
    theLog->setFile (0, local_dir + sep + "setup.log", true);

    log (LOG_PLAIN) << "Starting OSGeo4W install, version "
                    << setup_version << endLog;
    log (LOG_PLAIN) << "using locales " << locale << endLog;

    if (HelpOption)
      GetOption::GetInstance ()->ParameterUsage (log (LOG_PLAIN)
						<< "\nCommand Line Options:\n");
    else
      {
        UserSettings Settings (root);
        main_display ();
        Settings.save ();	// Clean exit.. save user options.
      }

    if (rebootneeded)
      {
        theLog->exit (IDS_REBOOT_REQUIRED);
      }
    else
      {
        theLog->exit (0);
      }
  }
  TOPLEVEL_CATCH("main");

  // Never reached
  return 0;
}
