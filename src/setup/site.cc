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

/* The purpose of this file is to get the list of mirror sites and ask
   the user which mirror site they want to download from. */

#if 0
static const char *cvsid =
  "\n%%% $Id: site.cc,v 2.52 2012/08/30 22:32:14 yselkowitz Exp $\n";
#endif

#include <string>
#include <algorithm>
#include <iterator>

#include "site.h"
#include "win32.h"
#include <stdio.h>
#include <stdlib.h>
#include <process.h>

#include "dialog.h"
#include "resource.h"
#include "state.h"
#include "geturl.h"
#include "msg.h"
#include "LogSingleton.h"
#include "io_stream.h"
#include "site.h"

#include "propsheet.h"

#include "threebar.h"
#include "ControlAdjuster.h"
#include "Exception.h"
#include "String++.h"

using namespace std;

extern ThreeBarProgressPage Progress;


/*
  What to do if dropped mirrors are selected.
*/
enum
{
  CACHE_REJECT,		// Go back to re-select mirrors.
  CACHE_ACCEPT_WARN,	// Go on. Warn again next time.
  CACHE_ACCEPT_NOWARN	// Go on. Don't warn again.
};

/*
  Sizing information.
 */
static ControlAdjuster::ControlInfo SiteControlsInfo[] = {
  {IDC_URL_LIST, 		CP_STRETCH, CP_STRETCH},
  {IDC_EDIT_USER_URL,		CP_STRETCH, CP_BOTTOM},
  {IDC_BUTTON_ADD_URL,		CP_RIGHT,   CP_BOTTOM},
  {IDC_SITE_USERURL,            CP_LEFT,    CP_BOTTOM},
  {0, CP_LEFT, CP_TOP}
};

SitePage::SitePage ()
{
  sizeProcessor.AddControlInfo (SiteControlsInfo);
}

#include "getopt++/StringArrayOption.h"
#include "getopt++/BoolOption.h"
#include "UserSettings.h"

using namespace std;

bool cache_is_usable;
bool cache_needs_writing;
string cache_warn_urls;

/* Selected sites */
SiteList site_list;

/* Fresh mirrors + selected sites */
SiteList all_site_list;

/* Previously fresh + cached before */
SiteList cached_site_list;

/* Stale selected sites to warn about and add to cache */
SiteList dropped_site_list;

StringArrayOption SiteOption('s', "site", "Download site");

BoolOption OnlySiteOption(false, 'O', "only-site", "Ignore all sites except for -s");

SiteSetting::SiteSetting (): saved (false)
{
  vector<string> SiteOptionStrings = SiteOption;
  if (SiteOptionStrings.size())
    {
      for (vector<string>::const_iterator n = SiteOptionStrings.begin ();
	   n != SiteOptionStrings.end (); ++n)
	registerSavedSite (n->c_str ());
    }
  else
    getSavedSites ();
}

void
SiteSetting::save()
{
  io_stream *f = UserSettings::instance().open ("last-mirror");
  if (f)
    {
      for (SiteList::const_iterator n = site_list.begin ();
           n != site_list.end (); ++n)
        *f << n->url;
      delete f;
    }
  saved = true;
}

SiteSetting::~SiteSetting ()
{
  if (!saved)
    save ();
}

void
site_list_type::init (const string &_url, const string &_servername,
                      const string &_area, const string &_location)
{
  url = _url;
  servername = _servername;
  area = _area;
  location = _location;

  /* Canonicalize URL to ensure it ends with a '/' */
  if (url.at(url.length()-1) != '/')
    url.append("/");

  /* displayed_url is protocol and site name part of url */
  displayed_url = url.substr (0, url.find ("/", url.find (".")));

  key = string();
  string::size_type last_idx = displayed_url.length () - 1;
  string::size_type idx = url.find_last_of("./", last_idx);
  if (last_idx - idx == 3)
  {
    /* Sort non-country TLDs (.com, .net, ...) together. */
    key += " ";
  }
  do
  {
    key += url.substr(idx + 1, last_idx - idx);
    key += " ";
    last_idx = idx - 1;
    idx = url.find_last_of("./", last_idx);
    if (idx == string::npos)
      idx = 0;
  } while (idx > 0);
  key += url;
}

site_list_type::site_list_type (const string &_url,
				const string &_servername,
				const string &_area,
				const string &_location)
{
  init (_url, _servername, _area, _location);
}

site_list_type::site_list_type (site_list_type const &rhs)
{
  key = rhs.key;
  url = rhs.url;
  servername = rhs.servername;
  area = rhs.area;
  location = rhs.location;
  displayed_url = rhs.displayed_url;
}

site_list_type &
site_list_type::operator= (site_list_type const &rhs)
{
  key = rhs.key;
  url = rhs.url;
  servername = rhs.servername;
  area = rhs.area;
  location = rhs.location;
  displayed_url = rhs.displayed_url;
  return *this;
}

bool
site_list_type::operator == (site_list_type const &rhs) const
{
  return stricmp (key.c_str(), rhs.key.c_str()) == 0;
}

bool
site_list_type::operator < (site_list_type const &rhs) const
{
  return stricmp (key.c_str(), rhs.key.c_str()) < 0;
}

static void
save_dialog (HWND h)
{
  // Remove anything that was previously in the selected site list.
  site_list.clear ();

  HWND listbox = GetDlgItem (h, IDC_URL_LIST);
  LRESULT sel_count = SendMessage (listbox, LB_GETSELCOUNT, 0, 0);
  if (sel_count > 0)
    {
      std::vector<int> sel_buffer(sel_count);
      SendMessage (listbox, LB_GETSELITEMS, sel_count, (LPARAM) sel_buffer.data());
      for (int n = 0; n < sel_count; n++)
        {
          LRESULT mirror =
            SendMessage (listbox, LB_GETITEMDATA, sel_buffer[n], 0);
          site_list.push_back (all_site_list[mirror]);
        }
    }
}

void
load_site_list (SiteList& theSites, char *theString)
{
  char *bol, *eol, *nl;

  nl = theString;
  while (*nl)
    {
      bol = nl;
      for (eol = bol; *eol && *eol != '\n'; eol++);
      if (*eol)
        nl = eol + 1;
      else
        nl = eol;
      while (eol > bol && eol[-1] == '\r')
        eol--;
      *eol = 0;
      if (*bol == '#' || !*bol)
        continue;
      /* Accept only the URL schemes we can understand. */
      if (strncmp(bol, "http://", 7) == 0 ||
          strncmp(bol, "ftp://", 6) == 0)
        {
          char *semi = strchr (bol, ';');
          char *semi2 = NULL;
          char *semi3 = NULL;
          if (semi)
          {
            *semi = 0;
            semi++;
            semi2 = strchr (semi, ';');
            if (semi2)
            {
              *semi2 = 0;
              semi2++;
              semi3 = strchr (semi2, ';');
              if (semi3)
              {
                *semi3 = 0;
                semi3++;
              }
            }
          }
          site_list_type newsite (bol, semi, semi2, semi3);
          SiteList::iterator i = find (theSites.begin(),
              theSites.end(), newsite);
          if (i == theSites.end())
          {
            SiteList result;
            merge (theSites.begin(), theSites.end(),
                &newsite, &newsite + 1,
                std::inserter (result, result.begin()));
            theSites = result;
          }
          else
            //TODO: remove and remerge
            *i = newsite;
        }
    }
}

static int
get_site_list (HINSTANCE h, HWND owner)
{
  char *theMirrorString, *theCachedString;
  const char *cached_mirrors = OnlySiteOption ? NULL : UserSettings::instance().get ("mirrors-lst");
  if (cached_mirrors)
    {
      log (LOG_BABBLE) << "Loaded cached mirror list" << endLog;
      cache_is_usable = true;
    }
  else
    {
      log (LOG_BABBLE) << "Cached mirror list unavailable" << endLog;
      cache_is_usable = false;
      cached_mirrors = "";
    }

  string mirrors = OnlySiteOption ? string ("") : get_url_to_string (OSGEO4W_MIRROR_URL, owner, true);
  if (mirrors.size())
    cache_needs_writing = true;
  else
    {
      if (!cached_mirrors[0])
        log (LOG_BABBLE) << "Defaulting to empty mirror list" << endLog;
      else
        {
          mirrors = cached_mirrors;
          log (LOG_BABBLE) << "Using cached mirror list" << endLog;
        }
      cache_is_usable = false;
      cache_needs_writing = false;
    }
  theMirrorString = new_cstr_char_array (mirrors);
  theCachedString = new_cstr_char_array (cached_mirrors);

  load_site_list (all_site_list, theMirrorString);
  load_site_list (cached_site_list, theCachedString);

  delete[] theMirrorString;
  delete[] theCachedString;

  return 0;
}

void
SiteSetting::registerSavedSite (const char * site)
{
  site_list_type tempSite(site, "", "", "");
  SiteList::iterator i = find (all_site_list.begin(),
			       all_site_list.end(), tempSite);
  if (i == all_site_list.end())
    {
      SiteList result;
      merge (all_site_list.begin(), all_site_list.end(),
	     &tempSite, &tempSite + 1,
	     inserter (result, result.begin()));
      all_site_list = result;
      site_list.push_back (tempSite);
    }
  else
    site_list.push_back (tempSite);
}

void
SiteSetting::getSavedSites ()
{
  const char *buf = UserSettings::instance().get ("last-mirror");
  if (!buf)
    return;
  char *fg_ret = strdup (buf);
  for (char *site = strtok (fg_ret, "\n"); site; site = strtok (NULL, "\n"))
    registerSavedSite (site);
  free (fg_ret);
}

static DWORD WINAPI
do_download_site_info_thread (void *p)
{
  HANDLE *context;
  HINSTANCE hinst;
  HWND h;
  context = (HANDLE *) p;

  try
  {
    hinst = (HINSTANCE) (context[0]);
    h = (HWND) (context[1]);
    static bool downloaded = false;
    if (!downloaded && get_site_list (hinst, h))
    {
      // Error: Couldn't download the site info.
      // Go back to the Net setup page.
      MessageBox (h, TEXT ("Can't get list of download sites.\n")
          TEXT("Make sure your network settings are correct and try again."),
          NULL, MB_OK);

      // Tell the progress page that we're done downloading
      Progress.PostMessageNow (WM_APP_SITE_INFO_DOWNLOAD_COMPLETE, 0, IDD_NET);
    }
    else
    {
      downloaded = true;
      // Everything worked, go to the site select page
      // Tell the progress page that we're done downloading
      Progress.PostMessageNow (WM_APP_SITE_INFO_DOWNLOAD_COMPLETE, 0, IDD_SITE);
    }
  }
  TOPLEVEL_CATCH("site");

  ExitThread(0);
}

static HANDLE context[2];

void
do_download_site_info (HINSTANCE hinst, HWND owner)
{
  context[0] = hinst;
  context[1] = owner;

  DWORD threadID;
  CreateThread (NULL, 0, do_download_site_info_thread, context, 0, &threadID);
}

static INT_PTR CALLBACK
drop_proc (HWND h, UINT message, WPARAM wParam, LPARAM lParam)
{
  switch (message)
    {
      case WM_INITDIALOG:
        eset(h, IDC_DROP_MIRRORS, cache_warn_urls);
	/* Should this be set by default? */
	// CheckDlgButton (h, IDC_DROP_NOWARN, BST_CHECKED);
	SetFocus (GetDlgItem(h, IDC_DROP_NOWARN));
	return FALSE;
	break;
      case WM_COMMAND:
	switch (LOWORD (wParam))
	  {
	    case IDYES:
	      if (IsDlgButtonChecked (h, IDC_DROP_NOWARN) == BST_CHECKED)
	        EndDialog (h, CACHE_ACCEPT_NOWARN);
	      else
	        EndDialog (h, CACHE_ACCEPT_WARN);
	      break;

	    case IDNO:
	      EndDialog (h, CACHE_REJECT);
	      break;

	    default:
	      return 0;
	  }
	return TRUE;

      default:
	return FALSE;
    }
}

INT_PTR check_dropped_mirrors (HWND h)
{
  cache_warn_urls = "";
  dropped_site_list.clear ();

  for (SiteList::const_iterator n = site_list.begin ();
       n != site_list.end (); ++n)
    {
      SiteList::iterator i = find (all_site_list.begin(), all_site_list.end(), *n);
      if (i == all_site_list.end() || !i->servername.size())
        {
          SiteList::iterator j = find (cached_site_list.begin(),
              cached_site_list.end(), *n);
          if (j != cached_site_list.end())
          {
            log (LOG_PLAIN) << "Dropped selected mirror: " << n->url
              << endLog;
            dropped_site_list.push_back (*j);
            if (cache_warn_urls.size())
              cache_warn_urls += "\r\n";
            cache_warn_urls += i->url;
          }
        }
    }
  if (cache_warn_urls.size())
    {
      if (unattended_mode)
        return CACHE_ACCEPT_WARN;
      return DialogBox (hinstance, MAKEINTRESOURCE (IDD_DROPPED), h,
			drop_proc);
    }
  return CACHE_ACCEPT_NOWARN;
}

void write_cache_list (io_stream *f, const SiteList& theSites)
{
  string s;
  for (SiteList::const_iterator n = theSites.begin ();
       n != theSites.end (); ++n)
    if (n->servername.size())
      *f << (n->url + ";" + n->servername + ";" + n->area + ";"
	     + n->location);
}

void save_cache_file (INT_PTR cache_action)
{
  string s;
  io_stream *f = UserSettings::instance().open ("mirrors-lst");
  if (f)
    {
      write_cache_list (f, all_site_list);
      if (cache_action == CACHE_ACCEPT_WARN)
	{
	  log (LOG_PLAIN) << "Adding dropped mirrors to cache to warn again."
	      << endLog;
	  *f << "# Following mirrors re-added by setup.exe to warn again about dropped urls.";
	  write_cache_list (f, dropped_site_list);
	}
      delete f;
    }
}

bool SitePage::Create ()
{
  return PropertyPage::Create (IDD_SITE);
}

long
SitePage::OnNext ()
{
  HWND h = GetHWND ();
  INT_PTR cache_action = CACHE_ACCEPT_NOWARN;

  save_dialog (h);

  if (cache_is_usable && !(cache_action = check_dropped_mirrors (h)))
    return -1;

  if (cache_needs_writing)
    save_cache_file (cache_action);

  // Log all the selected URLs from the list.
  for (SiteList::const_iterator n = site_list.begin ();
       n != site_list.end (); ++n)
    log (LOG_PLAIN) << "site: " << n->url << endLog;

  Progress.SetActivateTask (WM_APP_START_SETUP_INI_DOWNLOAD);
  return IDD_INSTATUS;
}

long
SitePage::OnBack ()
{
  HWND h = GetHWND ();

  save_dialog (h);

  // Go back to the net connection type page
  return 0;
}

void
SitePage::OnActivate ()
{
  // Fill the list box with all known sites.
  PopulateListBox ();

  // Load the user URL box with nothing - it is in the list already.
  eset (GetHWND (), IDC_EDIT_USER_URL, "");

  // Get the enabled/disabled states of the controls set accordingly.
  CheckControlsAndDisableAccordingly ();
}

long
SitePage::OnUnattended ()
{
  if (SendMessage (GetDlgItem (IDC_URL_LIST), LB_GETSELCOUNT, 0, 0) > 0)
    return OnNext ();
  else
    return -2;
}

void
SitePage::CheckControlsAndDisableAccordingly () const
{
  DWORD ButtonFlags = PSWIZB_BACK;

  // Check that at least one download site is selected.
  if (SendMessage (GetDlgItem (IDC_URL_LIST), LB_GETSELCOUNT, 0, 0) > 0)
    {
      // At least one site selected, enable "Next".
      ButtonFlags |= PSWIZB_NEXT;
    }
  GetOwner ()->SetButtons (ButtonFlags);
}

void
SitePage::PopulateListBox ()
{
  int j;
  HWND listbox = GetDlgItem (IDC_URL_LIST);

  // Populate the list box with the URLs.
  SendMessage (listbox, LB_RESETCONTENT, 0, 0);
  for (SiteList::const_iterator i = all_site_list.begin ();
       i != all_site_list.end (); ++i)
    {
      j = (int) SendMessage (listbox, LB_ADDSTRING, 0,
		       (LPARAM) i->displayed_url.c_str());
      SendMessage (listbox, LB_SETITEMDATA, j, j);
    }

  // Select the selected ones.
  for (SiteList::const_iterator n = site_list.begin ();
       n != site_list.end (); ++n)
    {
      int index = (int) SendMessage (listbox, LB_FINDSTRING, (WPARAM) - 1,
			       (LPARAM) n->displayed_url.c_str());
      if (index != LB_ERR)
        {
          // Highlight the selected item
          SendMessage (listbox, LB_SELITEMRANGE, TRUE, (index << 16) | index);
          // Make sure it's fully visible
          SendMessage (listbox, LB_SETCARETINDEX, index, FALSE);
        }
    }
}

bool SitePage::OnMessageCmd (int id, HWND hwndctl, UINT code)
{
  switch (id)
  {
    case IDC_EDIT_USER_URL:
      {
        // FIXME: Make Enter here cause an ADD, not a NEXT.
        break;
      }
    case IDC_URL_LIST:
      {
        if (code == LBN_SELCHANGE)
        {
          CheckControlsAndDisableAccordingly ();
          save_dialog (GetHWND ());
        }
        break;
      }
    case IDC_BUTTON_ADD_URL:
      {
        if (code == BN_CLICKED)
        {
          // User pushed the Add button.
          std::string other_url = egetString (GetHWND (), IDC_EDIT_USER_URL);
          if (other_url.size())
          {
            site_list_type newsite (other_url, "", "", "");
            SiteList::iterator i = find (all_site_list.begin(),
                all_site_list.end(), newsite);
            if (i == all_site_list.end())
            {
              all_site_list.push_back (newsite);
              log (LOG_BABBLE) << "Adding site: " << other_url << endLog;
            }
            else
            {
              *i = newsite;
              log (LOG_BABBLE) << "Replacing site: " << other_url << endLog;
            }

            // Assume the user wants to use it and select it for him.
            site_list.push_back (newsite);

            // Update the list box.
            PopulateListBox ();
            // And allow the user to continue
            CheckControlsAndDisableAccordingly ();
            eset (GetHWND (), IDC_EDIT_USER_URL, "");
          }
        }
        break;
      }
    default:
      // Wasn't recognized or handled.
      return false;
  }

  // Was handled since we never got to default above.
  return true;
}
