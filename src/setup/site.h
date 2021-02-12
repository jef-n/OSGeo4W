/*
 * Copyright (c) 2001, Robert Collins.
 *
 *     This program is free software; you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation; either version 2 of the License, or
 *     (at your option) any later version.
 *
 *     A copy of the GNU General Public License can be found at
 *     http://www.gnu.org/
 *
 * Written by Robert Collins <rbtcollins@hotmail.com>
 *
 */

#ifndef SETUP_SITE_H
#define SETUP_SITE_H

#include <string>
#include <vector>

#include "proppage.h"

class SitePage : public PropertyPage
{
public:
  SitePage ();
  virtual ~ SitePage ()
  {
  };

  bool Create ();

  virtual void OnActivate ();
  virtual long OnNext ();
  virtual long OnBack ();
  virtual long OnUnattended ();

  virtual bool OnMessageCmd (int id, HWND hwndctl, UINT code);

  void PopulateListBox();
  void CheckControlsAndDisableAccordingly () const;
};

void do_download_site_info (HINSTANCE h, HWND owner);

class site_list_type
{
public:
  site_list_type () : url (), displayed_url (), key () {};
  site_list_type (const site_list_type &);
  site_list_type (const std::string& , const std::string& ,
                  const std::string& , const std::string& );
  /* workaround for missing placement new in gcc 2.95 */
  void init (const std::string& , const std::string& ,
             const std::string& , const std::string& );
  ~site_list_type () {};
  site_list_type &operator= (const site_list_type &);
  std::string url;
  std::string servername;
  std::string area;
  std::string location;
  std::string displayed_url;
  std::string key;
  bool operator == (const site_list_type &) const;
  bool operator != (const site_list_type &) const;
  bool operator < (const site_list_type &) const;
  bool operator <= (const site_list_type &) const;
  bool operator > (const site_list_type &) const;
  bool operator >= (const site_list_type &) const;
};

typedef std::vector <site_list_type> SiteList;

/* user chosen sites */
extern SiteList site_list;
/* potential sites */
extern SiteList all_site_list;

class SiteSetting
{
  public:
    SiteSetting ();
    void save ();
    ~SiteSetting ();
  private:
    bool saved;
    void getSavedSites();
    void registerSavedSite(char const *);
};

#endif /* SETUP_SITE_H */
