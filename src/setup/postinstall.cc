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

/* The purpose of this file is to run all the post-install scripts
   in their various forms. */

#if 0
static const char *cvsid =
  "\n%%% $Id: postinstall.cc,v 2.29 2010/11/20 13:03:58 jturney Exp $\n";
#endif

#include "dialog.h"
#include "find.h"
#include "mount.h"
#include "script.h"
#include "state.h"
#include "FindVisitor.h"
#include "package_db.h"
#include "package_meta.h"
#include "resource.h"
#include "threebar.h"
#include "Exception.h"
#include "postinstallresults.h"

#include <algorithm>
#include <sstream>

using namespace std;

extern ThreeBarProgressPage Progress;
extern PostInstallResultsPage PostInstallResults;

// ---------------------------------------------------------------------------
//
// ---------------------------------------------------------------------------

class RunFindVisitor : public FindVisitor
{
public:
  RunFindVisitor (vector<Script> *scripts) : _scripts(scripts) {}
  virtual void visitFile(const std::string& basePath,
                         const WIN32_FIND_DATA *theFile)
    {
      std::string fileName(theFile->cFileName);
      if (fileName.size() >= 5 &&
          fileName.substr(fileName.size() - 5) == ".done")
        return;
      std::string fn = std::string("/etc/postinstall/") + theFile->cFileName;
      _scripts->push_back(Script (fn));
    }
  virtual ~ RunFindVisitor () {}
protected:
  RunFindVisitor (RunFindVisitor const &);
  RunFindVisitor & operator= (RunFindVisitor const &);
private:
  vector<Script> *_scripts;
};

// ---------------------------------------------------------------------------
//
// ---------------------------------------------------------------------------

class RunScript
{
public:
  RunScript(const std::string& name, const vector<Script> &scripts) : _name(name), _scripts(scripts), _cnt(0)
    {
      Progress.SetText2 (name.c_str());
      Progress.SetBar1 (0, _scripts.size());
    }
  virtual ~RunScript()
    {
      Progress.SetText3 ("");
    }
  int run_one(Script const &aScript)
    {
      int retval;
      Progress.SetText3 (aScript.fullName().c_str());
      retval = aScript.run();
      ++_cnt;
      Progress.SetBar1 (_cnt, _scripts.size());
      return retval;
    }
  void run_all(std::string &s)
  {
    bool package_name_recorded = FALSE;

    for (std::vector <Script>::const_iterator j = _scripts.begin();
         j != _scripts.end();
         j++)
      {
        int retval = run_one(*j);

        if ((retval != 0) && (retval != -ERROR_INVALID_DATA))
          {
            if (!package_name_recorded)
              {
                s = s + "Package: " + _name + "\r\n";
                package_name_recorded = TRUE;
              }

            std::ostringstream fs;
            fs << "\t" <<  j->baseName() << " exit code " << retval << "\r\n";
            s = s + fs.str();
          }
      }
  }
private:
  std::string _name;
  const vector<Script> &_scripts;
  int _cnt;
};

static std::string
do_postinstall_thread (HINSTANCE h, HWND owner)
{
  Progress.SetText1 ("Running...");
  Progress.SetText2 ("");
  Progress.SetText3 ("");
  Progress.SetBar1 (0, 1);
  Progress.SetBar2 (0, 1);

  init_run_script ();
  SetCurrentDirectory (get_root_dir ().c_str());
  packagedb db;
  vector<packagemeta*> packages;
  PackageDBConnectedIterator i = db.connectedBegin ();
  while (i != db.connectedEnd ())
    {
      packagemeta & pkg = **i;
      if (pkg.installed)
	packages.push_back(&pkg);
      ++i;
    }

  std::string s = "";

  // For each package we installed, we noted anything installed into /etc/postinstall.
  // run those scripts now
  size_t numpkg = packages.size() + 1;
  int k = 0;
  for (i = packages.begin (); i != packages.end (); ++i)
    {
      packagemeta & pkg = **i;

      RunScript scriptRunner(pkg.name, pkg.installed.scripts());
      scriptRunner.run_all(s);

      ++k;
      Progress.SetBar2 (k, numpkg);
    }

  // Look for any scripts in /etc/postinstall which haven't been renamed .done
  std::string postinst = cygpath ("/etc/postinstall");
  vector<Script> scripts;
  RunFindVisitor myVisitor (&scripts);
  Find (postinst).accept (myVisitor);

  // Remove anything which we just tried to run (so we don't try twice)
  for (i = packages.begin (); i != packages.end (); ++i)
    {
       packagemeta & pkg = **i;
       for (std::vector<Script>::const_iterator j = pkg.installed.scripts().begin();
            j != pkg.installed.scripts().end();
            j++)
         {
           std::vector<Script>::iterator p = find(scripts.begin(), scripts.end(), *j);
           if (p != scripts.end())
             {
               scripts.erase(p);
             }
         }
    }

  // and try to run what's left...
  {
    RunScript scriptRunner("Unknown package", scripts);
    scriptRunner.run_all(s);
  }

  Progress.SetBar2 (numpkg, numpkg);

  return s;
}

static DWORD WINAPI
do_postinstall_reflector (void *p)
{
  HANDLE *context;
  context = (HANDLE *) p;

  try
  {
    std::string s = do_postinstall_thread ((HINSTANCE) context[0], (HWND) context[1]);

    // Tell the postinstall results page the results string
    PostInstallResults.SetResultsString(s);

    // Tell the progress page that we're done running scripts
    Progress.PostMessageNow (WM_APP_POSTINSTALL_THREAD_COMPLETE, 0,
                          s.empty() ? IDD_DESKTOP : IDD_POSTINSTALL);
  }
  TOPLEVEL_CATCH("postinstall");

  ExitThread(0);
}

static HANDLE context[2];

void
do_postinstall (HINSTANCE h, HWND owner)
{
  context[0] = h;
  context[1] = owner;

  DWORD threadID;
  CreateThread (NULL, 0, do_postinstall_reflector, context, 0, &threadID);
}

