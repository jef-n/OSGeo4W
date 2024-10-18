/*
 * Copyright (c) 2000,2007 Red Hat, Inc.
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

/* The purpose of this file is to get and parse the setup.ini file
   from the mirror site.  A few support routines for the bison and
   flex parsers are provided also.  We check to see if this setup.ini
   is older than the one we used last time, and if so, warn the user. */

#include "ini.h"

#include "csu_util/rfc1738.h"
#include "csu_util/version_compare.h"

#include "setup_version.h"
#include "win32.h"
#include "LogSingleton.h"

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <process.h>

#include "resource.h"
#include "state.h"
#include "geturl.h"
#include "dialog.h"
#include "msg.h"
#include "mount.h"
#include "site.h"
#include "find.h"
#include "IniParseFindVisitor.h"
#include "IniParseFeedback.h"

#include "io_stream.h"
#include "io_stream_memory.h"

#include "threebar.h"

#include "getopt++/BoolOption.h"
#include "IniDBBuilderPackage.h"
#include "compress.h"
#include "Exception.h"
#include "package_db.h"
#include "package_meta.h"
#include "package_version.h"

#include <algorithm>

extern ThreeBarProgressPage Progress;

unsigned int setup_timestamp = 0;
std::string ini_setup_version;

extern int yyparse ();
/*extern int yydebug;*/

using namespace std;

class GuiParseFeedback : public IniParseFeedback
{
public:
  GuiParseFeedback () : lastpct (0)
    {
      Progress.SetText2 ("");
      Progress.SetText3 ("");
      Progress.SetText4 (Window::loadRString(IDS_PROGRESS).c_str());
    }
  virtual void progress(unsigned long const pos, unsigned long const max)
    {
      if (!max)
        /* length not known or eof */
        return;
      if (lastpct == 100)
        /* rounding down should mean this only ever fires once */
        lastpct = 0;
      if (pos * 100 / max > lastpct)
        {
          lastpct = pos * 100 / max;
        }
      Progress.SetBar1(pos, max);

      std::string buf = Window::sprintf( "%d %%  (%ldk/%ldk)", lastpct, pos/1000, max/1000);
      Progress.SetText3(buf.c_str());
    }
  virtual void iniName (const std::string& name)
    {
      Progress.SetText1 ("Parsing...");
      Progress.SetText2 (name.c_str());
      Progress.SetText3 ("");
    }
  virtual void babble(const std::string& message)const
    {
      log (LOG_BABBLE) << message << endLog;
    }
  virtual void warning (const std::string& message)const
    {
      MessageBox (0, message.c_str(), "Warning", 0);
    }
  virtual void error(const std::string& message)const
    {
      MessageBox (0, message.c_str(), "Parse Errors", 0);
    }
  virtual ~ GuiParseFeedback ()
    {
      Progress.SetText4("Package:");
    }
private:
  unsigned int lastpct;
};

static int
do_local_ini (HWND)
{
  GuiParseFeedback myFeedback;
  IniDBBuilderPackage findBuilder(myFeedback);
  IniParseFindVisitor myVisitor (findBuilder, local_dir, myFeedback);
  Find (local_dir).accept(myVisitor, 2);        // Only search two levels deep.
  setup_timestamp = myVisitor.timeStamp();
  ini_setup_version = myVisitor.version();
  return myVisitor.iniCount();
}

static int
do_remote_ini (HWND owner)
{
  int ini_count = 0;
  GuiParseFeedback myFeedback;
  IniDBBuilderPackage aBuilder(myFeedback);
  io_stream *ini_file;

  /* FIXME: Get rid of this io_stream pointer travesty.  The need to
     explicitly delete these things is ridiculous.  Note that the
     decompress io_stream "owns" the underlying compressed io_stream
     instance, so it should not be deleted explicitly.  */

  for (SiteList::const_iterator n = site_list.begin();
       n != site_list.end(); ++n)
    {
      /* First try to fetch the .bz2 compressed ini file.  */
      current_ini_name = n->url + SETUP_INI_DIR + SETUP_BZ2_FILENAME;
      ini_file = get_url_to_membuf (current_ini_name, owner, true);
      if ( ini_file )
        {
          /* Decompress the entire file in memory right now.  This has the
             advantage that input_stream->get_size() will work during parsing
             and we'll have an accurate status bar.  Also, we can't seek
             bz2 streams, so when it comes time to write out a local cached
             copy of the .ini file below, we'd otherwise have to delete this
             stream and uncompress it again from the start, which is wasteful.
             The current uncompressed size of the .ini file as of 2007 is less
             than 600 kB, so this is not a great deal of memory.  */
          io_stream *bz2_stream = compress::decompress (ini_file);
          if (!bz2_stream)
            {
              /* This isn't a valid bz2 file. */
              delete ini_file;
              ini_file = NULL;
            }
          else
            {
              io_stream *uncompressed = new io_stream_memory ();

              if (io_stream::copy (bz2_stream, uncompressed) != 0 ||
                  bz2_stream->error () == EIO)
                {
                  /* There was a problem decompressing bz2.  */
                  delete bz2_stream;
                  delete uncompressed;
                  ini_file = NULL;
                  log (LOG_PLAIN) <<
                    "Warning: Problem encountered while uncompressing " <<
                    current_ini_name << " - possibly truncated or corrupt bzip2"
                    " file.  Retrying with uncompressed version." << endLog;
                }
              else
                {
                  delete bz2_stream;
                  ini_file = uncompressed;
                  ini_file->seek (0, IO_SEEK_SET);
                }
            }
        }

      if (!ini_file)
        {
          /* Try to look for a plain .ini file because one of the following
             happened above:
               - there was no .bz2 file found on the mirror.
               - the .bz2 file didn't look like a valid bzip2 file.
               - there was an error during bzip2 decompression.  */
          current_ini_name = n->url + SETUP_INI_DIR + SETUP_INI_FILENAME;
          ini_file = get_url_to_membuf (current_ini_name, owner, true);
        }

      if (!ini_file)
        {
          note (owner, IDS_SETUPINI_MISSING, SETUP_INI_FILENAME, n->url.c_str());
          continue;
        }

      myFeedback.iniName (current_ini_name);
      aBuilder.parse_mirror = n->url;
      ini_init (ini_file, &aBuilder, myFeedback);

      /*yydebug = 1; */

      if (yyparse () || yyerror_count > 0)
        myFeedback.error (yyerror_messages);
      else
        {
          /* save known-good setup.ini locally */
          const std::string fp = "file://" + local_dir + "/" +
                                  rfc1738_escape_part (n->url) +
                                  "/" + SETUP_INI_DIR + SETUP_INI_FILENAME;
          io_stream::mkpath_p (PATH_TO_FILE, fp);
          if (io_stream *out = io_stream::open (fp, "wb"))
          {
            ini_file->seek (0, IO_SEEK_SET);
            if (io_stream::copy (ini_file, out) != 0)
              io_stream::remove (fp);
            delete out;
          }
          ++ini_count;
        }
      if (aBuilder.timestamp > setup_timestamp)
        {
          setup_timestamp = aBuilder.timestamp;
          ini_setup_version = aBuilder.version;
        }
      delete ini_file;
    }
  return ini_count;
}

static bool
do_ini_thread (HINSTANCE h, HWND owner)
{
  size_t ini_count = 0;
  if (source == IDC_SOURCE_CWD)
    ini_count = do_local_ini (owner);
  else
    ini_count = do_remote_ini (owner);

  if (ini_count == 0)
    return false;

  if (get_root_dir ().c_str())
    {
      io_stream::mkpath_p (PATH_TO_DIR, "cygfile:///etc/setup");

      unsigned int old_timestamp = 0;
      io_stream *ots =
        io_stream::open ("cygfile:///etc/setup/timestamp", "rt");
      if (ots)
        {
          char temp[20];
          memset (temp, '\0', 20);
          if (ots->read (temp, 19))
            sscanf (temp, "%u", &old_timestamp);
          delete ots;
          if (old_timestamp && setup_timestamp
              && (old_timestamp > setup_timestamp))
            {
              int yn = yesno (owner, IDS_OLD_SETUPINI);
              if (yn == IDNO)
                LogSingleton::GetInstance().exit (1);
            }
        }
      if (setup_timestamp)
        {
          io_stream *nts =
            io_stream::open ("cygfile:///etc/setup/timestamp", "wt");
          if (nts)
            {
              char temp[20];
              sprintf (temp, "%u", setup_timestamp);
              nts->write (temp, strlen (temp));
              delete nts;
            }
        }
    }

  msg (".ini setup_version is %s, our setup_version is %s\n", ini_setup_version.size() ?
       ini_setup_version.c_str () : "(null)",
       setup_version);
  if (ini_setup_version.size ())
    {
      if (version_compare (setup_version, ini_setup_version) < 0)
        note (owner, IDS_OLD_SETUP_VERSION, setup_version,
              ini_setup_version.c_str ());
    }

  return true;
}

static DWORD WINAPI
do_ini_thread_reflector(void* p)
{
  HANDLE *context;
  context = (HANDLE*)p;

  try
  {
    bool succeeded = do_ini_thread((HINSTANCE)context[0], (HWND)context[1]);

    // Tell the progress page that we're done downloading
    Progress.PostMessageNow(WM_APP_SETUP_INI_DOWNLOAD_COMPLETE, 0, succeeded);
  }
  TOPLEVEL_CATCH("ini");

  ExitThread(0);
}

static HANDLE context[2];

void
do_ini (HINSTANCE h, HWND owner)
{
  context[0] = h;
  context[1] = owner;

  DWORD threadID;
  CreateThread (NULL, 0, do_ini_thread_reflector, context, 0, &threadID);
}


struct MatchPathSeparator
{
  bool operator()( char ch ) const
  {
      return isdirsep(ch);
  }
};

std::string
basename( std::string const& pathname )
{
  return std::string(
      std::find_if( pathname.rbegin(), pathname.rend(),
        MatchPathSeparator() ).base(), pathname.end() );
}

bool isDot(char c)
{
  return c == '.';
}

static int
do_fetch_license (HWND owner)
{
  int lic_count = 0;
  io_stream *lic_file = NULL;

  std::string path_license;
  std::string file_name;

  packagedb db;
  for (packagedb::packagecollection::iterator i = db.packages.begin (); i != db.packages.end (); ++i)
    {
      packagemeta &pkg = *(i->second);

      if ( !pkg.desired.picked() && !pkg.desired.sourcePackage().picked() )
        continue;

      // skip already installed packages
      if ( pkg.installed && pkg.desired == pkg.installed )
        continue;

      for(multimap<string, RestrictivePackage *>::iterator it = packagedb::blacklist.begin();
          it != packagedb::blacklist.end(); it++  )
        {
          RestrictivePackage &rp = *it->second;
          if( rp.agree_license || rp.name != pkg.name )
            continue;

          rp.selectedpkg = true;

          if( source != IDC_SOURCE_CWD)
            {
              for (SiteList::const_iterator n = site_list.begin();
                  n != site_list.end(); ++n)
                {
                  rp.local_path = "file://" + local_dir + "/" + rfc1738_escape_part( n->url ) + "/" + rp.remote_path;

                  std::string url = n->url + rp.remote_path;
                  std::string file_name = basename(rp.remote_path);

                  // we create a memory
                  lic_file = get_url_to_membuf (url, owner, true);
                  if( !lic_file )
                    {
                      log (LOG_BABBLE) << "Unable to get license file " << file_name.c_str() << " from <" << url.c_str() << ">" << endLog;
                      continue;
                    }

                  log (LOG_BABBLE) << "Using remote path: " << url.c_str() << endLog;
                  io_stream::mkpath_p (PATH_TO_FILE, rp.local_path);

                  log (LOG_BABBLE) << "saving file locally in " << rp.local_path << endLog;

                  if (io_stream *out = io_stream::open (rp.local_path, "wb"))
                    {
                      lic_file->seek (0, IO_SEEK_SET);
                      if (io_stream::copy (lic_file, out) != 0)
                        io_stream::remove (rp.local_path);
                      delete out;
                    }

                  // save all non- open source licenses under an specific directory
                  std::string fp = std::string("file://") + get_root_dir() + std::string("/etc/licenses/") + file_name;
                  io_stream::mkpath_p (PATH_TO_FILE, fp);

                  log (LOG_BABBLE) << "saving file locally in " << fp << endLog;

                  if (io_stream *out = io_stream::open (fp, "wb"))
                    {
                      lic_file->seek (0, IO_SEEK_SET);
                      if (io_stream::copy (lic_file, out) != 0)
                        io_stream::remove (fp);
                      delete out;
                    }

                  delete lic_file;
                  break;
                }
            }
          else
            {
              rp.local_path = "file://" + local_dir + "/" + rp.remote_path;
              if ( !io_stream::exists(rp.local_path) )
                {
                  packagesource *pkgsource = pkg.desired.source();
                  for (packagesource::sitestype::const_iterator n=pkgsource->sites.begin();
                      n != pkgsource->sites.end(); ++n)
                    {
                      rp.local_path = "file://" + local_dir + "/" + rfc1738_escape_part( n->key ) + "/" + rp.remote_path;
                      if (io_stream::exists(rp.local_path))
                        break;
                    }
                }
            }

          ++lic_count;
        }
    }

  return lic_count;
}

static bool
do_license_thread(HINSTANCE h, HWND owner)
{
  return do_fetch_license (owner) > 0;
}

static DWORD WINAPI
do_license_thread_reflector(void* p)
{
  HANDLE *context;
  context = (HANDLE*)p;

  try
  {
    bool succeeded = do_license_thread((HINSTANCE)context[0], (HWND)context[1]);

    // Tell the progress page that we're done downloading
    Progress.PostMessageNow(WM_APP_LICENSE_FILE_DOWNLOAD_COMPLETE, 0, succeeded);
  }
  TOPLEVEL_CATCH("license");

  ExitThread(0);
}

void do_license(HINSTANCE h, HWND owner)
{
  context[0] = h;
  context[1] = owner;

  DWORD threadID;
  CreateThread (NULL, 0, do_license_thread_reflector, context, 0, &threadID);
}
