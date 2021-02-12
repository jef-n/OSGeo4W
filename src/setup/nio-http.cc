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

/* This file is responsible for implementing all direct HTTP protocol
   channels.  It is intentionally simplistic. */

#if 0
static const char *cvsid =
  "\n%%% $Id: nio-http.cc,v 2.17 2006/04/15 21:21:25 maxb Exp $\n";
#endif

#include "win32.h"
#include "winsock.h"
#include <stdio.h>
#include <stdlib.h>

#include "resource.h"
#include "state.h"
#include "simpsock.h"
#include "msg.h"

#include "netio.h"
#include "nio-http.h"

#include "String++.h"

#if !defined(_strnicmp) && !defined(_MSC_VER)
#define _strnicmp strncasecmp
#endif

static char six2pr[64] = {
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
  'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
  'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
  'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
  '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '/'
};

static char *
base64_encode (char *username, char *password)
{
  unsigned char *ep;
  char *rp;
  static char *rv = 0;
  if (rv)
    delete[] rv;
  rv = new char[2 * (strlen (username) + strlen (password)) + 5];

  char *up = new char[strlen (username) + strlen (password) + 6];
  strcpy (up, username);
  strcat (up, ":");
  strcat (up, password);
  ep = (unsigned char *) up + strlen (up);
  *ep++ = 0;
  *ep++ = 0;
  *ep++ = 0;

  char block[4];

  rp = rv;

  for (ep = (unsigned char *) up; *ep; ep += 3)
    {
      block[0] = six2pr[ep[0] >> 2];
      block[1] = six2pr[((ep[0] << 4) & 0x30) | ((ep[1] >> 4) & 0x0f)];
      block[2] = six2pr[((ep[1] << 2) & 0x3c) | ((ep[2] >> 6) & 0x03)];
      block[3] = six2pr[ep[2] & 0x3f];

      if (ep[1] == 0)
	block[2] = block[3] = '=';
      if (ep[2] == 0)
	block[3] = '=';
      memcpy (rp, block, 4);
      rp += 4;
    }
  *rp = 0;

  delete[] up;

  return rv;
}

NetIO_HTTP::NetIO_HTTP (char const *Purl, bool nocache):NetIO (Purl)
{
retry_get:
  if (port == 0)
    port = 80;

  if (net_method == IDC_NET_PROXY)
    s = new SimpleSocket (net_proxy_host, net_proxy_port);
  else
    s = new SimpleSocket (host, port);

  if (!s->ok ())
    {
      delete
	s;
      s = NULL;
      return;
    }

  if (net_method == IDC_NET_PROXY)
    s->printf ("GET %s HTTP/1.0\r\n", Purl);
  else
    s->printf ("GET %s HTTP/1.0\r\n", path);

  // Default HTTP port is 80. Host header can have no port if requested port
  // is the same as the default.  Some HTTP servers don't behave as expected
  // when they receive a Host header with the unnecessary default port value.
  if (port == 80)
    s->printf ("Host: %s\r\n", host);
  else
    s->printf ("Host: %s:%d\r\n", host, port);

  if (net_user && net_passwd)
    s->printf ("Authorization: Basic %s\r\n",
	       base64_encode (net_user, net_passwd));

  if (net_proxy_user && net_proxy_passwd)
    s->printf ("Proxy-Authorization: Basic %s\r\n",
	       base64_encode (net_proxy_user, net_proxy_passwd));

  if ( nocache )
    s->printf( "Cache-Control: no-cache\r\n" );

  s->printf ("\r\n");

  char *
    l = s->gets ();
  int
    code;
  if (!l)
    return;
  sscanf (l, "%*s %d", &code);
  if (code >= 300 && code < 400)
    {
      while ((l = s->gets ()) != 0)
	{
	  if (_strnicmp (l, "Location:", 9) == 0)
	    {
	      char *
		u = l + 9;
	      while (*u == ' ' || *u == '\t')
		u++;
	      set_url (u);
	      delete
		s;
	      goto retry_get;
	    }
	}
    }
  if (code == 401)		/* authorization required */
    {
      get_auth (NULL);
      delete
	s;
      goto retry_get;
    }
  if (code == 407)		/* proxy authorization required */
    {
      get_proxy_auth (NULL);
      delete
	s;
      goto retry_get;
    }
  if (code == 500		/* ftp authentication through proxy required */
      && net_method == IDC_NET_PROXY && !strncmp (Purl, "ftp://", 6))
    {
      get_ftp_auth (NULL);
      if (net_ftp_user && net_ftp_passwd)
	{
	  delete
	    s;
	  Purl = (std::string("ftp://") + net_ftp_user +
			":" + net_ftp_passwd + "@" + (Purl + 6)).c_str();
	  goto retry_get;
	}
    }
  if (code >= 300)
    {
      delete
	s;
      s = 0;
      return;
    }
  
  // Eat the header, picking out the Content-Length in the process
  while (((l = s->gets ()) != NULL) && (*l != '\0'))
    {
      if (_strnicmp (l, "Content-Length:", 15) == 0)
      {
        size_t s;
        if( sscanf (l+15, PRSIZE_T, &s) == 1 )
          file_size = s;
	else
          msg( "Could not parse content length [%s]\n", l );
      }
    }
}

NetIO_HTTP::~NetIO_HTTP ()
{
  if (s)
    delete s;
}

int
NetIO_HTTP::ok ()
{
  if (s && s->ok ())
    return 1;
  return 0;
}

ssize_t
NetIO_HTTP::read (char *buf, size_t nbytes)
{
  return s->read (buf, nbytes);
}
