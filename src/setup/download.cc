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

/* The purpose of this file is to download all the files we need to
   do the installation. */

#if 0
static const char *cvsid =
  "\n%%% $Id: download.cc,v 2.56 2012/11/08 19:12:16 yselkowitz Exp $\n";
#endif

#include "csu_util/rfc1738.h"

#include "download.h"

#include "win32.h"

#include <stdio.h>
#include <unistd.h>
#include <process.h>

#include "resource.h"
#include "msg.h"
#include "dialog.h"
#include "geturl.h"
#include "state.h"
#include "LogSingleton.h"
#include "filemanip.h"

#include "io_stream.h"

#include "package_db.h"
#include "package_meta.h"
#include "package_version.h"
#include "package_source.h"

#include "threebar.h"

#include "Exception.h"

#include "getopt++/BoolOption.h"

using namespace std;

extern ThreeBarProgressPage Progress;

static bool
validateCachedPackage (const std::string& fullname, packagesource & pkgsource)
{
  size_t size = get_file_size(fullname);
  if (size != pkgsource.size)
  {
    log (LOG_BABBLE) << "INVALID PACKAGE: " << fullname
      << " - Size mismatch: Ini-file: " << pkgsource.size
      << " != On-disk: " << size << endLog;
    return false;
  }
  return true;
}

/* 0 on failure
 */
int
check_for_cached (packagesource & pkgsource)
{
  /* search algo:
     1) is there a legacy version in the cache dir available.
     (Note that the cache dir is represented by a mirror site of
     file://local_dir
   */

  // Already found one.
  if (pkgsource.Cached())
    return 1;

  std::string prefix = "file://" + local_dir + "/";
  /* FIXME: Nullness check can go away once packagesource is properly
   * std::string-ified, and doesn't use overcomplex semantics. */
  std::string fullname = prefix +
    (pkgsource.Canonical() ? pkgsource.Canonical() : "");
  if (io_stream::exists(fullname))
  {
    if (validateCachedPackage (fullname, pkgsource))
      pkgsource.set_cached (fullname);
    else
      throw new Exception (TOSTRING(__LINE__) " " __FILE__,
          "Package validation failure for " + fullname,
          APPERR_CORRUPT_PACKAGE);
    return 1;
  }

  /*
     2) is there a version from one of the selected mirror sites available ?
     */
  for (packagesource::sitestype::const_iterator n = pkgsource.sites.begin();
       n != pkgsource.sites.end(); ++n)
  {
    std::string fullname = prefix + rfc1738_escape_part (n->key) + "/" +
      pkgsource.Canonical ();
    if (io_stream::exists(fullname))
    {
      if (validateCachedPackage (fullname, pkgsource))
        pkgsource.set_cached (fullname);
      else
        throw new Exception (TOSTRING(__LINE__) " " __FILE__,
            "Package validation failure for " + fullname,
            APPERR_CORRUPT_PACKAGE);
      return 1;
    }
  }
  return 0;
}

/* download a file from a mirror site to the local cache. */
static int
download_one (packagesource & pkgsource, HWND owner)
{
  try
    {
      if (check_for_cached (pkgsource))
        return 0;
    }
  catch (Exception * e)
    {
      // We know what to do with these..
      if (e->errNo() == APPERR_CORRUPT_PACKAGE)
        {
          fatal (owner, IDS_CORRUPT_PACKAGE, pkgsource.Canonical());
          return 1;
        }
      // Unexpected exception.
      throw e;
    }
  /* try the download sites one after another */

  int success = 0;
  for (packagesource::sitestype::const_iterator n = pkgsource.sites.begin();
       n != pkgsource.sites.end() && !success; ++n)
    {
      const std::string local = local_dir + "/" +
                                rfc1738_escape_part (n->key) + "/" +
                                pkgsource.Canonical ();
      io_stream::mkpath_p (PATH_TO_FILE, "file://" + local);

      if (get_url_to_file(n->key +  "/" + pkgsource.Canonical (),
                          local + ".tmp", pkgsource.size, owner))
        {
          /* FIXME: note new source ? */
          continue;
        }
      else
        {
          size_t size = get_file_size ("file://" + local + ".tmp");
          if (size == pkgsource.size)
            {
              log (LOG_PLAIN) << "Downloaded " << local << endLog;
              if (_access (local.c_str(), 0) == 0)
                remove (local.c_str());
              rename ((local + ".tmp").c_str(), local.c_str());
              success = 1;
              pkgsource.set_cached ("file://" + local);
              // FIXME: move the downloaded file to the 
              //  original locations - without the mirror site dir in the way
              continue;
            }
          else
            {
              log (LOG_PLAIN) << "Download " << local << " wrong size (" <<
                size << " actual vs " << pkgsource.size << " expected)" << 
                endLog;
              remove ((local + ".tmp").c_str());
              continue;
            }
        }
    }
  if (success)
    return 0;
  /* FIXME: Do we want to note this? if so how? */
  return 1;
}

static int
do_download_thread (HINSTANCE h, HWND owner)
{
  int errors = 0;
  total_download_bytes = 0;
  total_download_bytes_sofar = 0;

  Progress.SetText1 ("Checking for packages to download...");
  Progress.SetText2 ("");
  Progress.SetText3 ("");

  packagedb db;
  /* calculate the amount needed */
  for (packagedb::packagecollection::iterator i = db.packages.begin ();
       i != db.packages.end (); ++i)
    {
      packagemeta & pkg = *(i->second);
      if (pkg.desired.picked () || pkg.desired.sourcePackage ().picked ())
	{
	  packageversion version = pkg.desired;
	  packageversion sourceversion = version.sourcePackage();
	  try
	    {
    	      if (version.picked())
		{
		  for (vector<packagesource>::iterator i =
		       version.sources ()->begin();
		       i != version.sources ()->end(); ++i)
		    if (!check_for_cached (*i))
      		      total_download_bytes += i->size;
		}
    	      if (sourceversion.picked ())
		{
		  for (vector<packagesource>::iterator i =
		       sourceversion.sources ()->begin();
		       i != sourceversion.sources ()->end(); ++i)
		    if (!check_for_cached (*i))
		      total_download_bytes += i->size;
		}
	    }
	  catch (Exception * e)
	    {
	      // We know what to do with these..
	      if (e->errNo() == APPERR_CORRUPT_PACKAGE)
		fatal (owner, IDS_CORRUPT_PACKAGE, pkg.name.c_str());
	      // Unexpected exception.
	      throw e;
	    }
	}
    }

  /* and do the download. FIXME: This here we assign a new name for the cached version
   * and check that above.
   */
  for (packagedb::packagecollection::iterator i = db.packages.begin ();
       i != db.packages.end (); ++i)
    {
      packagemeta & pkg = *(i->second);
      if (pkg.desired.picked () || pkg.desired.sourcePackage ().picked ())
	{
	  int e = 0;
	  packageversion version = pkg.desired;
	  packageversion sourceversion = version.sourcePackage();
	  if (version.picked())
	    {
	      for (vector<packagesource>::iterator i =
   		   version.sources ()->begin();
		   i != version.sources ()->end(); ++i)
    		e += download_one (*i, owner);
	    }
	  if (sourceversion && sourceversion.picked())
	    {
	      for (vector<packagesource>::iterator i =
   		   sourceversion.sources ()->begin();
		   i != sourceversion.sources ()->end(); ++i)
    		e += download_one (*i, owner);
	    }
	  errors += e;
#if 0
	  if (e)
	    pkg->action = ACTION_ERROR;
#endif
	}
    }

  if (errors)
    {
      /* In unattended mode, all dialog boxes automatically get
         answered with a Yes/OK/other positive response.  This
	 means that if there's a download problem, setup will
	 potentially retry forever if we don't take care to give
	 up at some finite point.  */
      static int retries = 4;
      if (unattended_mode && retries-- <= 0)
        {
	  log (LOG_PLAIN) << "download error in unattended_mode: out of retries" << endLog;
	  exit_msg = IDS_INSTALL_INCOMPLETE;
	  LogSingleton::GetInstance().exit (1);
	}
      else if (unattended_mode)
        {
	  log (LOG_PLAIN) << "download error in unattended_mode: " << retries
	    << (retries > 1 ? " retries" : " retry") << " remaining." << endLog;
	  return IDD_SITE;
	}
      else if (yesno (owner, IDS_DOWNLOAD_INCOMPLETE) == IDYES)
	return IDD_SITE;
    }

  if (source == IDC_SOURCE_DOWNLOAD)
    {
      if (errors)
	exit_msg = IDS_DOWNLOAD_INCOMPLETE;
      else if (!unattended_mode)
	exit_msg = IDS_DOWNLOAD_COMPLETE;
      return IDD_DESKTOP;
    }
  else
    return IDD_S_INSTALL;
}

static DWORD WINAPI
do_download_reflector (void *p)
{
  HANDLE *context;
  context = (HANDLE *) p;

  try
  {
    int next_dialog =
      do_download_thread ((HINSTANCE) context[0], (HWND) context[1]);

    // Tell the progress page that we're done downloading
    Progress.PostMessageNow (WM_APP_DOWNLOAD_THREAD_COMPLETE, 0, next_dialog);
  }
  TOPLEVEL_CATCH("download");

  ExitThread(0);
}

static HANDLE context[2];

void
do_download (HINSTANCE h, HWND owner)
{
  context[0] = h;
  context[1] = owner;

  DWORD threadID;
  CreateThread (NULL, 0, do_download_reflector, context, 0, &threadID);
}
