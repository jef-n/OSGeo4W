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

/* The purpose of this file is to manage internet downloads using the
   Internet Explorer version 5 DLLs.  To use this method, the user
   must already have installed and configured IE5.  This module is
   called from netio.cc, which is called from geturl.cc */

#if 0
static const char *cvsid =
  "\n%%% $Id: nio-ie5.cc,v 2.6 2002/06/15 12:13:29 rbcollins Exp $\n";
#endif

#include "win32.h"

#include "resource.h"
#include "state.h"
#include "dialog.h"
#include "msg.h"
#include "netio.h"
#include "nio-ie5.h"

static HINTERNET internet = 0;

NetIO_IE5::NetIO_IE5 (char const *_url):
NetIO (_url)
{
  int resend = 0;

  if (internet == 0)
    {
      HINSTANCE h = LoadLibrary ("wininet.dll");
      if (!h)
	{
	  note (NULL, IDS_WININET);
	  connection = 0;
	  return;
	}
      InternetAttemptConnect (0);
      internet = InternetOpen ("OSGeo4W Setup", INTERNET_OPEN_TYPE_PRECONFIG,
			       NULL, NULL, 0);
    }

  DWORD flags =
 //    INTERNET_FLAG_DONT_CACHE |
    INTERNET_FLAG_KEEP_CONNECTION |
 //   INTERNET_FLAG_PRAGMA_NOCACHE |
 //   INTERNET_FLAG_RELOAD |
    INTERNET_FLAG_EXISTING_CONNECT | INTERNET_FLAG_PASSIVE;

  connection = InternetOpenUrl (internet, url, NULL, 0, flags, 0);

try_again:

  if (net_user && net_passwd)
    {
      InternetSetOption (connection, INTERNET_OPTION_USERNAME,
			 net_user, (DWORD) strlen (net_user));
      InternetSetOption (connection, INTERNET_OPTION_PASSWORD,
			 net_passwd, (DWORD) strlen (net_passwd));
    }

  if (net_proxy_user && net_proxy_passwd)
    {
      InternetSetOption (connection, INTERNET_OPTION_PROXY_USERNAME,
			 net_proxy_user, (DWORD) strlen (net_proxy_user));
      InternetSetOption (connection, INTERNET_OPTION_PROXY_PASSWORD,
			 net_proxy_passwd, (DWORD) strlen (net_proxy_passwd));
    }

  if (resend)
    if (!HttpSendRequest (connection, 0, 0, 0, 0))
      connection = 0;

  if (!connection)
    {
      if (GetLastError () == ERROR_INTERNET_EXTENDED_ERROR)
	{
	  char buf[2000];
	  DWORD e, l = sizeof buf;
	  InternetGetLastResponseInfo (&e, buf, &l);
	  MessageBox (0, buf, "Internet Error", 0);
	}
    }

  DWORD type, type_s;
  type_s = sizeof type;
  InternetQueryOption (connection, INTERNET_OPTION_HANDLE_TYPE,
		       &type, &type_s);

  switch (type)
    {
    case INTERNET_HANDLE_TYPE_HTTP_REQUEST:
    case INTERNET_HANDLE_TYPE_CONNECT_HTTP:
      type_s = sizeof(DWORD);
      if (HttpQueryInfo (connection,
			 HTTP_QUERY_STATUS_CODE | HTTP_QUERY_FLAG_NUMBER,
			 &type, &type_s, NULL))
	{
	  if (type == 401)	/* authorization required */
	    {
	      flush_io ();
	      get_auth (NULL);
	      resend = 1;
	      goto try_again;
	    }
	  else if (type == 407)	/* proxy authorization required */
	    {
	      flush_io ();
	      get_proxy_auth (NULL);
	      resend = 1;
	      goto try_again;
	    }
	  else if (type >= 300)
	    {
	      connection = 0;
	      return;
	    }
	}
    }
}

void
NetIO_IE5::flush_io ()
{
  DWORD actual = 0;
  char buf[1024];
  do
    {
      InternetReadFile (connection, buf, 1024, &actual);
    }
  while (actual > 0);
}

NetIO_IE5::~NetIO_IE5 ()
{
  if (connection)
    InternetCloseHandle (connection);
}

int
NetIO_IE5::ok ()
{
  return (connection == NULL) ? 0 : 1;
}

ssize_t
NetIO_IE5::read (char *buf, size_t nbytes)
{
  DWORD actual;
  if (InternetReadFile (connection, buf, (DWORD) nbytes, &actual))
    return actual;
  return -1;
}
