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

/* Simplified socket access functions */

#if 0
static const char *cvsid =
  "\n%%% $Id: simpsock.cc,v 2.6 2002/01/20 13:31:04 rbcollins Exp $\n";
#endif

#include "win32.h"
#include <winsock.h>
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>

#include "simpsock.h"
#include "msg.h"

#define SSBUFSZ 1024

SimpleSocket::SimpleSocket (const char *hostname, int port)
{
  static int initted = 0;
  if (!initted)
    {
      initted = 1;
      WSADATA d;
      WSAStartup (MAKEWORD (1, 1), &d);
    }

  s = INVALID_SOCKET;
  buf = 0;
  putp = getp = 0;

  int i1, i2, i3, i4;
  unsigned char ip[4];

  if (sscanf (hostname, "%d.%d.%d.%d", &i1, &i2, &i3, &i4) == 4)
    {
      ip[0] = i1;
      ip[1] = i2;
      ip[2] = i3;
      ip[3] = i4;
    }
  else
    {
      struct hostent *he;
      he = gethostbyname (hostname);
      if (!he)
	{
	  msg ("Can't resolve `%s'\n", hostname);
	  return;
	}
      memcpy (ip, he->h_addr_list[0], 4);
    }

  s = socket (AF_INET, SOCK_STREAM, 0);
  if (s == INVALID_SOCKET)
    {
      msg ("Can't create socket, %d", WSAGetLastError ());
      return;
    }

  struct sockaddr_in name;

  memset (&name, 0, sizeof name);
  name.sin_family = AF_INET;
  name.sin_port = htons (port);
  memcpy (&name.sin_addr, ip, 4);

  if (connect (s, (sockaddr *) & name, sizeof name))
    {
      msg ("Can't connect to %s:%d", hostname, port);
      closesocket (s);
      s = INVALID_SOCKET;
      return;
    }

  return;
}

SimpleSocket::~SimpleSocket ()
{
  invalidate ();
}

int
SimpleSocket::ok ()
{
  if (s == INVALID_SOCKET)
    return 0;
  return 1;
}

int
SimpleSocket::printf (const char *fmt, ...)
{
  char buf[SSBUFSZ];
  va_list args;
  va_start (args, fmt);
  vsprintf (buf, fmt, args);
  return write (buf, strlen (buf));
}

int
SimpleSocket::write (const char *buf, size_t len)
{
  int rv;
  if (!ok ())
    return -1;
  if ((rv = send (s, buf, (int) len, 0)) == -1)
    invalidate ();
  return rv;
}

int
SimpleSocket::fill ()
{
  if (!ok ())
    return -1;

  if (buf == 0)
    buf = new char [SSBUFSZ + 3];
  if (putp == getp)
    putp = getp = 0;

  int n = (int) (SSBUFSZ - putp);
  if (n == 0)
    return 0;
  int r = recv (s, buf + putp, (int) n, 0);
  if (r > 0)
    {
      putp += r;
    }
  else if (r < 0 && putp == getp)
    {
      invalidate ();
    }
  return r;
}

char *
SimpleSocket::gets ()
{
  if (getp > 0 && putp > getp)
    {
      memmove (buf, buf + getp, putp - getp);
      putp -= getp;
      getp = 0;
    }
  if (putp == getp)
    if (fill () <= 0)
      return 0;

  // getp is zero, always, here, and putp is the count
  char *nl;
  while ((nl = (char *) memchr (buf, '\n', putp)) == NULL && putp < SSBUFSZ)
    if (fill () <= 0)
      break;

  if (nl)
    {
      getp = nl - buf + 1;
      while ((*nl == '\n' || *nl == '\r') && nl >= buf)
	*nl-- = 0;
    }
  else if (putp > getp)
    {
      getp = putp;
      nl = buf + putp;
      nl[1] = 0;
    }
  else
    return 0;

  return buf;
}

ssize_t
SimpleSocket::read (char *ubuf, size_t ulen)
{
  if (!ok ())
    return -1;

  int n, rv = 0;
  if (putp > getp)
    {
      n = (int) std::min ( ulen, putp - getp);
      memmove (ubuf, buf + getp, n);
      getp += n;
      ubuf += n;
      ulen -= n;
      rv += n;
    }
  while (ulen > 0)
    {
      n = recv (s, ubuf, (int) ulen, 0);
      if (n < 0)
        invalidate ();
      if (n <= 0)
        return rv > 0 ? rv : n;
      ubuf += n;
      ulen -= n;
      rv += n;
    }
  return rv;
}

void
SimpleSocket::invalidate (void)
{
  if (s != INVALID_SOCKET)
    closesocket (s);
  s = INVALID_SOCKET;
  if (buf)
    delete[] buf;
  buf = 0;
  getp = putp = 0;
}
