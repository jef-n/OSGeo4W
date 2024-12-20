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
 * Originally Written by DJ Delorie <dj@cygnus.com>
 *
 */

/* The purpose of this file is to install all the packages selected in
   the install list (in ini.h).  Note that we use a separate thread to
   maintain the progress dialog, so we avoid the complexity of
   handling two tasks in one thread.  We also create or update all the
   files in /etc/setup/\* and create the mount points. */

#include "getopt++/BoolOption.h"
#include "csu_util/MD5Sum.h"
#include "LogSingleton.h"

#include "win32.h"
#include "commctrl.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
#include <process.h>

#include "ini.h"
#include "resource.h"
#include "dialog.h"
#include "geturl.h"
#include "state.h"
#include "diskfull.h"
#include "msg.h"
#include "mount.h"
#include "mount.h"
#include "filemanip.h"
#include "io_stream.h"
#include "io_stream_file.h"
#include "compress.h"
#include "compress_gz.h"
#include "archive.h"
#include "archive_tar.h"
#include "script.h"

#include "package_db.h"
#include "package_meta.h"
#include "package_version.h"
#include "package_source.h"

#include "threebar.h"
#include "Exception.h"

using namespace std;

extern ThreeBarProgressPage Progress;

static size_t total_bytes = 0;
static size_t total_bytes_sofar = 0;
static size_t package_bytes = 0;

static BoolOption NoReplaceOnReboot (false, 'r', "no-replaceonreboot",
				     "Disable replacing in-use files on next "
				     "reboot.");

class Installer
{
  public:
    Installer();
    void initDialog();
    void progress (size_t bytes);
    void preremoveOne (packagemeta &);
    void uninstallOne (packagemeta &);
    void replaceOnRebootFailed (const std::string& fn);
    void replaceOnRebootSucceeded (const std::string& fn, bool &rebootneeded);
    void installOne (packagemeta &pkg, const packageversion &ver,
                     packagesource &source,
                     const std::string& , const std::string&, HWND );
    int errors;
  private:
    bool extract_replace_on_reboot(archive *, const std::string&,
                                   const std::string&, std::string);

};

Installer::Installer() : errors(0)
{
}

void
Installer::initDialog()
{
  Progress.SetText2 ("");
  Progress.SetText3 ("");
}

void
Installer::progress (size_t bytes)
{
  if (package_bytes > 0)
      Progress.SetBar1 (bytes, package_bytes);

  if (total_bytes > 0)
      Progress.SetBar2 (total_bytes_sofar + bytes, total_bytes);
}

static int num_installs, num_uninstalls;
static void md5_one (const packagesource& source);

void
Installer::preremoveOne (packagemeta & pkg)
{
  Progress.SetText1 (Window::loadRString(IDS_RUNNING_PREREMOVE).c_str());
  Progress.SetText2 (pkg.name.c_str());
  log (LOG_PLAIN) << "Running preremove script for  " << pkg.name << endLog;
  try_run_script ("/etc/preremove/", pkg.name, ".sh");
  try_run_script ("/etc/preremove/", pkg.name, ".bat");
}

void
Installer::uninstallOne (packagemeta & pkg)
{
  Progress.SetText1 (Window::loadRString(IDS_UNINSTALLING).c_str());
  Progress.SetText2 (pkg.name.c_str());
  log (LOG_PLAIN) << "Uninstalling " << pkg.name << endLog;
  pkg.uninstall ();
  num_uninstalls++;
}

/* log failed scheduling of replace-on-reboot of a given file. */
/* also increment errors. */
void
Installer::replaceOnRebootFailed (const std::string& fn)
{
  log (LOG_TIMESTAMP) << "Unable to schedule reboot replacement of file "
    << cygpath("/" + fn) << " with " << cygpath("/" + fn + ".new")
    << " (Win32 Error " << GetLastError() << ")" << endLog;
  ++errors;
}

/* log successful scheduling of replace-on-reboot of a given file. */
/* also set rebootneeded. */
void
Installer::replaceOnRebootSucceeded (const std::string& fn, bool &rebootneeded)
{
  log (LOG_TIMESTAMP) << "Scheduled reboot replacement of file "
    << cygpath("/" + fn) << " with " << cygpath("/" + fn + ".new") << endLog;
  rebootneeded = true;
}

#define MB_RETRYCONTINUE 7
#if !defined(IDCONTINUE)
#define IDCONTINUE IDCANCEL
#endif

static HHOOK hMsgBoxHook;
LRESULT CALLBACK CBTProc(int nCode, WPARAM wParam, LPARAM lParam) {
  HWND hWnd;
  switch (nCode) {
    case HCBT_ACTIVATE:
      hWnd = (HWND)wParam;
      if (GetDlgItem(hWnd, IDCANCEL) != NULL)
         SetDlgItemText(hWnd, IDCANCEL, "Continue");
      UnhookWindowsHookEx(hMsgBoxHook);
  }
  return CallNextHookEx(hMsgBoxHook, nCode, wParam, lParam);
}

int _custom_MessageBox(HWND hWnd, LPCTSTR szText, LPCTSTR szCaption, UINT uType) {
  int retval;
  bool retry_continue = (uType & MB_TYPEMASK) == MB_RETRYCONTINUE;
  if (retry_continue) {
    uType &= ~MB_TYPEMASK; uType |= MB_RETRYCANCEL;
    // Install a window hook, so we can intercept the message-box
    // creation, and customize it
    // Only install for THIS thread!!!
    hMsgBoxHook = SetWindowsHookEx(WH_CBT, CBTProc, NULL, GetCurrentThreadId());
  }
  retval = MessageBox(hWnd, szText, szCaption, uType);
  // Intercept the return value for less confusing results
  if (retry_continue && retval == IDCANCEL)
    return IDCONTINUE;
  return retval;
}

#undef MessageBox
#define MessageBox _custom_MessageBox

/* install one source at a given prefix. */
void
Installer::installOne (packagemeta &pkgm, const packageversion &ver,
                       packagesource &source,
                       const std::string& prefixURL,
                       const std::string& prefixPath,
                       HWND owner)
{
  if (!source.Canonical())
    return;

  Progress.SetText1 (Window::loadRString(IDS_INSTALLING).c_str());
  Progress.SetText2 (source.Base () ? source.Base () : "(unknown)");

  io_stream *pkgfile = NULL;

  if (!source.Cached() || !io_stream::exists (source.Cached ())
      || !(pkgfile = io_stream::open (source.Cached (), "rb")))
    {
      note (NULL, IDS_ERR_OPEN_READ, source.Cached (), "No such file");
      ++errors;
      return;
    }


  /* At this point pkgfile is an opened io_stream to either a .tar.bz2 file,
     a .tar.gz file, or just a .tar file.  Try it first as a compressed file
     and if that fails try opening it as a tar directly.  If both fail, abort.

     Note on io_stream pointer management:

     Both the archive and decompress classes take ownership of the io_stream
     pointer they were opened with, meaning they delete it in their dtor.  So
     deleting tarstream should also result in deleting the underlying
     try_decompress and pkgfile io_streams as well.  */

  archive *tarstream = NULL;
  io_stream *try_decompress = NULL;

  if ((try_decompress = compress::decompress (pkgfile)) != NULL)
    {
      if ((tarstream = archive::extract (try_decompress)) == NULL)
        {
          /* Decompression succeeded but we couldn't grok it as a valid tar
             archive, so notify the user and abort processing this package.  */
          delete try_decompress;
          note (NULL, IDS_ERR_OPEN_READ, source.Cached (),
                "Invalid or unsupported tar format");
          ++errors;
          return;
        }
    }
  else if ((tarstream = archive::extract (pkgfile)) == NULL)
    {
      /* Not a compressed tarball, not a plain tarball, give up.  */
      delete pkgfile;
      note (NULL, IDS_ERR_OPEN_READ, source.Cached (),
            "Unrecognisable file format");
      ++errors;
      return;
    }

  /* For binary packages, create a manifest in /etc/setup/ that lists the
     filename of each file that was unpacked.  */

  io_stream *lst = NULL;
  if (ver.Type () == package_binary)
    {
      std::string lstfn = "cygfile:///etc/setup/" + pkgm.name + ".lst.gz";

      io_stream *tmp;
      if ((tmp = io_stream::open (lstfn, "wb")) == NULL)
        log (LOG_PLAIN) << "Warning: Unable to create lst file " + lstfn +
          " - uninstall of this package will leave orphaned files." << endLog;
      else
        {
          lst = new compress_gz (tmp, "w9");
          if (lst->error ())
            {
              delete lst;
              lst = NULL;
              log (LOG_PLAIN) << "Warning: gzip unable to write to lst file " +
                lstfn + " - uninstall of this package will leave orphaned files."
                << endLog;
            }
        }
    }

  bool error_in_this_package = false;
  bool ignoreExtractErrors = unattended_mode != attended;

  package_bytes = source.size;
  log (LOG_PLAIN) << "Extracting from " << source.Cached () << endLog;

  std::string fn;
  while ((fn = tarstream->next_file_name ()).size ())
    {
      std::string canonicalfn = prefixPath + fn;
      Progress.SetText3 (canonicalfn.c_str ());
      log (LOG_BABBLE) << "Installing file " << prefixURL << prefixPath
          << fn << endLog;
      if (lst)
        {
          std::string tmp = fn + "\n";
          lst->write (tmp.c_str(), tmp.size());
        }
      if (Script::isAScript (fn))
        pkgm.desired.addScript (Script (canonicalfn));

      int iteration = 0;
      archive::extract_results extres;
      while ((extres = archive::extract_file (tarstream, prefixURL, prefixPath)) != archive::extract_ok)
        {
          time_t t = time(NULL);

          switch (extres)
            {
	    case archive::extract_inuse: // in use
	      // Try renaming in-use file by appending .epoch, removing a
	      // potentially existing one first and retry to extract
	      {
	        std::string s = cygpath ("/" + fn),
			    d = cygpath ("/" + fn + "." + std::to_string(t));
		if ( io_stream_file::exists(d) )
		  {
		    if( io_stream_file::remove (d) == 0 )
                      log (LOG_BABBLE) << "Old copy " << d << " of in-use file removed." << endLog;
		    else
                      log (LOG_BABBLE) << "Old copy " << d << " of in-use file could not be removed." << endLog;
		  }

		if( io_stream_file::move (s, d) != 0 )
                  log (LOG_BABBLE) << "In-use file " << s << " could not be renamed to " << d << endLog;
		else
		  {
                    log (LOG_BABBLE) << "In-use file " << s << " renamed to " << d << endLog;

		    if (archive::extract_file (tarstream, prefixURL, prefixPath) == archive::extract_ok)
		      {
			if ( is_elevated() && !NoReplaceOnReboot)
			  {
			    // cleanup old on next reboot
			    if (!MoveFileEx (d.c_str (), NULL, MOVEFILE_DELAY_UNTIL_REBOOT ))
			      {
			        log (LOG_TIMESTAMP) << "Unable to schedule reboot removal of file "
                                  << d
                                  << " (Win32 Error " << GetLastError() << ")" << endLog;
			      }
			    else
                              {
                                log (LOG_BABBLE) << "In-use file " << d << " will be removed on next reboot." << endLog;
			      }
			  }
			break;
		     }
		  }
	      }
              if (!ignoreExtractErrors)
                {
		  switch (MessageBox (NULL, Window::sprintf( Window::loadRString(iteration == 0 ? IDS_UNABLE_TO_EXTRACT : IDS_STILL_UNABLE_TO_EXTRACT).c_str(), fn.c_str() ).c_str(), Window::loadRString(IDS_UNABLE_TO_EXTRACT_CAPTION).c_str(), MB_RETRYCONTINUE | MB_ICONWARNING | MB_TASKMODAL))
                    {
                      case IDRETRY:
                        // retry
                        iteration = 0;
                        continue;
                      case IDCONTINUE:
                        iteration++;
                        break;
                      default:
                        break;
                    }

                  // fall through to previous functionality
                }
              if ( !is_elevated() || NoReplaceOnReboot )
                {
                  ++errors;
                  error_in_this_package = true;
                  log (LOG_PLAIN) << "Not replacing in-use file " << prefixURL
                    << prefixPath << fn << endLog;
                }
              else
                {
                  /* Extract a copy of the file with extension .new appended and
                     indicate it should be replaced on the next reboot.  */
                  if (archive::extract_file (tarstream, prefixURL, prefixPath,
                                             ".new") != 0)
                    {
                      log (LOG_PLAIN) << "Unable to install file " << prefixURL
                          << prefixPath << fn << ".new" << endLog;
                      ++errors;
                      error_in_this_package = true;
                    }
                  else
                    {
                      std::string s = cygpath ("/" + fn + ".new"),
                                  d = cygpath ("/" + fn);

                      /* XXX FIXME: prefix may not be / for in use files -
                       * although it most likely is
                       * - we need a io method to get win32 paths
                       * or to wrap this system call
                       */
                      if (!MoveFileEx (s.c_str (), d.c_str (),
                                       MOVEFILE_DELAY_UNTIL_REBOOT |
                                       MOVEFILE_REPLACE_EXISTING))
                        replaceOnRebootFailed (fn);
                      else
                        replaceOnRebootSucceeded (fn, rebootneeded);
                    }
                }
              break;
	    case archive::extract_other: // extract failed
              {
                if (!ignoreExtractErrors)
                  {
                    // XXX: We should offer the option to retry,
                    // continue without extracting this particular archive,
                    // or ignore all extraction errors.
                    // Unfortunately, we don't currently know how to rewind
                    // the archive, so we can't retry at present,
                    // and ignore all errors is mis-implemented at present
                    // to only apply to errors arising from a single archive,
                    // so we degenerate to the continue option.
                    MessageBox (owner, Window::sprintf( Window::loadRString(IDS_FILE_EXTRACTION_ERROR).c_str(), fn.c_str()).c_str(), Window::loadRString(IDS_FILE_EXTRACTION_CAPTION).c_str(), MB_OK | MB_ICONWARNING | MB_TASKMODAL);
                  }

                // don't mark this package as successfully installed
                error_in_this_package = true;
              }
              break;
	    case archive::extract_ok:
	      break;
            }
          // We're done with this file
          break;
        }
      progress (pkgfile->tell ());
      num_installs++;
    }

  if (lst)
    delete lst;
  delete tarstream;

  total_bytes_sofar += package_bytes;
  progress (0);

  int df = diskfull (get_root_dir ().c_str ());
  Progress.SetBar3 (df);

  if (ver.Type () == package_binary && !error_in_this_package)
    pkgm.installed = ver;
}

static void
do_install_thread (HINSTANCE h, HWND owner)
{
  num_installs = 0, num_uninstalls = 0;
  rebootneeded = false;

  io_stream::mkpath_p (PATH_TO_DIR,
                       std::string("file://") + std::string(get_root_dir()));

  Installer myInstaller;
  myInstaller.initDialog();

  total_bytes = 0;
  total_bytes_sofar = 0;

  int df = diskfull (get_root_dir ().c_str());
  Progress.SetBar3 (df);

  /* Let's hope people won't uninstall packages before installing [b]ash */
  init_run_script ();

  vector <packagemeta *> install_q, uninstall_q, sourceinstall_q;

  packagedb db;

  /* Calculate the amount of data to md5sum */
  Progress.SetText1 (Window::loadRString(IDS_CALCULATING).c_str());
  size_t md5sum_total_bytes = 0;
  for (packagedb::packagecollection::iterator i = db.packages.begin ();
       i != db.packages.end (); ++i)
  {
    packagemeta & pkg = *(i->second);

    if (pkg.desired.picked())
    {
      md5sum_total_bytes += pkg.desired.source()->size;
    }

    if (pkg.desired.sourcePackage ().picked())
    {
      md5sum_total_bytes += pkg.desired.sourcePackage ().source()->size;
    }
  }

  /* md5sum the packages, build lists of packages to install and uninstall
     and calculate the total amount of data to install */
  size_t md5sum_total_bytes_sofar = 0;
  for (packagedb::packagecollection::iterator i = db.packages.begin ();
       i != db.packages.end (); ++i)
  {
    packagemeta & pkg = *(i->second);

    if (pkg.desired.picked())
    {
      try
      {
        md5_one (*pkg.desired.source ());
      }
      catch (Exception *e)
      {
        if (yesno (owner, IDS_SKIP_PACKAGE, e->what()) == IDYES)
          pkg.desired.pick (false, &pkg);
      }
      if (pkg.desired.picked())
      {
        md5sum_total_bytes_sofar += pkg.desired.source()->size;
        total_bytes += pkg.desired.source()->size;
        install_q.push_back (&pkg);
      }
    }

    if (pkg.desired.sourcePackage ().picked())
    {
      try
      {
        md5_one (*pkg.desired.sourcePackage ().source ());
      }
      catch (Exception *e)
      {
        if (yesno (owner, IDS_SKIP_PACKAGE, e->what()) == IDYES)
          pkg.desired.sourcePackage ().pick (false, &pkg);
      }
      if (pkg.desired.sourcePackage().picked())
      {
        md5sum_total_bytes_sofar += pkg.desired.sourcePackage ().source()->size;
        total_bytes += pkg.desired.sourcePackage ().source()->size;
        sourceinstall_q.push_back (&pkg);
      }
    }

    if ((pkg.installed && pkg.desired != pkg.installed)
        || pkg.installed.picked ())
    {
      uninstall_q.push_back (&pkg);
    }

    if (md5sum_total_bytes > 0)
      Progress.SetBar2 (md5sum_total_bytes_sofar, md5sum_total_bytes);
  }

  /* start with uninstalls - remove files that new packages may replace */
  for (vector <packagemeta *>::iterator i = uninstall_q.begin ();
       i != uninstall_q.end (); ++i)
  {
    myInstaller.preremoveOne (**i);
  }
  for (vector <packagemeta *>::iterator i = uninstall_q.begin ();
       i != uninstall_q.end (); ++i)
  {
    myInstaller.uninstallOne (**i);
  }

  for (vector <packagemeta *>::iterator i = install_q.begin ();
       i != install_q.end (); ++i)
  {
    packagemeta & pkg = **i;
    try {
      myInstaller.installOne (pkg, pkg.desired, *pkg.desired.source(),
                              "cygfile://", "/", owner);
    }
    catch (exception *e)
    {
      if (yesno (owner, IDS_INSTALL_ERROR, e->what()) != IDYES)
      {
        log (LOG_TIMESTAMP)
          << "User cancelled setup after install error" << endLog;
        LogSingleton::GetInstance().exit (1);
        return;
      }
    }
  }

  for (vector <packagemeta *>::iterator i = sourceinstall_q.begin ();
       i != sourceinstall_q.end (); ++i)
  {
    packagemeta & pkg = **i;
    myInstaller.installOne (pkg, pkg.desired.sourcePackage(),
                            *pkg.desired.sourcePackage().source(),
                            "cygfile://", "/usr/src/", owner);
  }

  if (rebootneeded)
    note (owner, IDS_REBOOT_REQUIRED);

  int temperr;
  if ((temperr = db.flush ()))
    {
      const char *err = strerror (temperr);
      if (!err)
	err = "(unknown error)";
      fatal (owner, IDS_ERR_OPEN_WRITE, "Package Database",
	  err);
    }

  if (num_installs == 0 && num_uninstalls == 0)
    {
      if (!unattended_mode) exit_msg = IDS_NOTHING_INSTALLED;
      return;
    }
  if (num_installs == 0)
    {
      if (!unattended_mode) exit_msg = IDS_UNINSTALL_COMPLETE;
      return;
    }

  if (myInstaller.errors)
    exit_msg = IDS_INSTALL_INCOMPLETE;
  else if (!unattended_mode)
    exit_msg = IDS_INSTALL_COMPLETE;

  if (rebootneeded)
    exit_msg = IDS_REBOOT_REQUIRED;
}

static DWORD WINAPI
do_install_reflector (void *p)
{
  HANDLE *context;
  context = (HANDLE *) p;

  try
  {
    do_install_thread ((HINSTANCE) context[0], (HWND) context[1]);

    // Tell the progress page that we're done downloading
    Progress.PostMessageNow (WM_APP_INSTALL_THREAD_COMPLETE);
  }
  TOPLEVEL_CATCH("install");

  ExitThread (0);
}

static HANDLE context[2];

void
do_install (HINSTANCE h, HWND owner)
{
  context[0] = h;
  context[1] = owner;

  DWORD threadID;
  CreateThread (NULL, 0, do_install_reflector, context, 0, &threadID);
}

void md5_one (const packagesource& pkgsource)
{
  if (pkgsource.md5.isSet() && pkgsource.Cached ())
  {
    std::string fullname (pkgsource.Cached ());

    io_stream *thefile = io_stream::open (fullname, "rb");
    if (!thefile)
      throw new Exception (TOSTRING (__LINE__) " " __FILE__,
                           std::string ("IO Error opening ") + fullname,
                           APPERR_IO_ERROR);
    MD5Sum tempMD5;
    tempMD5.begin ();

    log (LOG_BABBLE) << "Checking MD5 for " << fullname << endLog;

    std::string msg = Window::sprintf(Window::loadRString(IDS_MD5CHECK).c_str(), pkgsource.Base());
    Progress.SetText1 (msg.c_str());
    Progress.SetText4 (Window::loadRString(IDS_PROGRESS).c_str());
    Progress.SetBar1 (0);

    unsigned char buffer[16384];
    ssize_t count;
    while ((count = thefile->read (buffer, sizeof buffer)) > 0)
    {
      tempMD5.append (buffer, (int) count);
      Progress.SetBar1 (thefile->tell (), thefile->get_size ());
    }
    delete thefile;
    if (count < 0)
      throw new Exception (TOSTRING(__LINE__) " " __FILE__,
                           "IO Error reading " + fullname,
                           APPERR_IO_ERROR);

    tempMD5.finish ();

    if (pkgsource.md5 != tempMD5)
    {
      log (LOG_BABBLE) << "INVALID PACKAGE: " << fullname
        << " - MD5 mismatch: Ini-file: " << pkgsource.md5.str()
        << " != On-disk: " << tempMD5.str() << endLog;
      throw new Exception (TOSTRING(__LINE__) " " __FILE__,
                           "MD5 failure for " + fullname,
                           APPERR_CORRUPT_PACKAGE);
    }

    log (LOG_BABBLE) << "MD5 verified OK: " << fullname << " "
      << pkgsource.md5.str() << endLog;
  }
}
