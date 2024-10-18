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

#ifndef SETUP_NETIO_H
#define SETUP_NETIO_H

#include "win32.h"

#ifdef _MSC_VER
#include <BaseTsd.h>
typedef SSIZE_T ssize_t;
#endif

/* This is the parent class for all the access methods known to setup
   (i.e. ways to download files from the internet or other sources */

class NetIO
{
protected:
  static char *net_user;
  static char *net_passwd;
  static char *net_proxy_user;
  static char *net_proxy_passwd;
  static char *net_ftp_user;
  static char *net_ftp_passwd;


public:
  /* if nonzero, this is the estimated total file size */
  size_t file_size;

  NetIO () : file_size(0) {};
  virtual ~ NetIO () {};

  /* The user calls this function to create a suitable accessor for
     the given URL.  It uses the network setup state in state.h.  If
     anything fails, either the return values is NULL or the returned
     object is !ok() */
  static NetIO *open (char const *url, bool cacheable);

  /* If !ok() that means the transfer isn't happening. */
  virtual int ok () = 0;

  /* Read `nbytes' bytes from the file.  Returns zero when the file
     is complete. */
  virtual ssize_t read (char *buf, size_t nbytes) = 0;

  static int net_method;
  static char *net_proxy_host;
  static int net_proxy_port;

  static const char *net_method_name();

  /* Helper functions for http/ftp protocols.  Both return nonzero for
     "cancel", zero for "ok".  They set net_proxy_user, etc, in
     state.h */
  INT_PTR get_auth (HWND owner);
  INT_PTR get_proxy_auth (HWND owner);
  INT_PTR get_ftp_auth (HWND owner);
};

#endif /* SETUP_NETIO_H */
