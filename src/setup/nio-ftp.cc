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

/* This file is responsible for implementing all direct FTP protocol
   channels.  It is intentionally simplistic. */

#if 0
static const char *cvsid =
  "\n%%% $Id: nio-ftp.cc,v 2.19 2012/02/19 13:57:03 corinna Exp $\n";
#endif

#include "nio-ftp.h"

#include "LogSingleton.h"

#include "win32.h"
#include "winsock.h"
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>

#include "resource.h"
#include "state.h"
#include "simpsock.h"

static SimpleSocket *cmd = 0;
static char *cmd_host = 0;
static int cmd_port = 0;

static char *last_line;

static int
ftp_line (SimpleSocket * s)
{
  do
    {
      last_line = s->gets ();
      log (LOG_BABBLE) << "ftp > " << (last_line ? last_line : "error")
        << endLog;
    }
  while (last_line && (!isdigit (last_line[0]) || last_line[3] != ' '));
  return atoi (last_line ? last_line : "0");
}

NetIO_FTP::NetIO_FTP (char const *Purl):NetIO (Purl)
{
  s = 0;
  int
    code;

  if (port == 0)
    port = 21;

control_reconnect:
  if ((cmd_host && strcmp (host, cmd_host) != 0) || port != cmd_port)
    {
      if (cmd)
	cmd->printf ("QUIT\r\n");
      delete cmd;
      delete [] cmd_host;
      cmd = 0;
      cmd_host = 0;
    }

  if (cmd == 0)
    {
      SimpleSocket *
	c = new SimpleSocket (host, port);
      code = ftp_line (c);

    auth_retry:
      if (net_ftp_user)
	c->printf ("USER %s\r\n", net_ftp_user);
      else
	c->printf ("USER anonymous\r\n");
      code = ftp_line (c);
      if (code == 331)
	{
	  if (net_ftp_passwd)
	    c->printf ("PASS %s\r\n", net_ftp_passwd);
	  else
	    c->printf ("PASS cygwin-setup@\r\n");
	  code = ftp_line (c);
	}
      if (code == 530)		/* Authentication failed, retry */
	{
	  get_ftp_auth (NULL);
	  if (net_ftp_user && net_ftp_passwd)
	    goto auth_retry;
	}

      if (code < 200 || code >= 300)
	{
	  delete
	    c;
	  return;
	}

      cmd = c;
      cmd_host = new char [strlen (host) + 1];
      strcpy (cmd_host, host);
      cmd_port = port;

      cmd->printf ("TYPE I\r\n");
      code = ftp_line (cmd);
    }

  cmd->printf ("PASV\r\n");
  do
    {
      code = ftp_line (cmd);
    }
  while (code == 226);		/* previous RETR */
  if (code == 421)              /* Timeout, retry */
    {
      log (LOG_BABBLE) << "FTP timeout -- reconnecting" << endLog;
      delete [] cmd_host;
      cmd_host = new char[1]; cmd_host[0] = '\0';
      goto control_reconnect;
    }
  if (code != 227)
    return;

  char *
    digit = strpbrk (last_line + 3, "0123456789");
  if (!digit)
    return;

  int
    i1, i2, i3, i4, p1, p2;
  sscanf (digit, "%d,%d,%d,%d,%d,%d", &i1, &i2, &i3, &i4, &p1, &p2);
  char
    tmp[20];
  sprintf (tmp, "%d.%d.%d.%d", i1, i2, i3, i4);
  s = new SimpleSocket (tmp, p1 * 256 + p2);

  cmd->printf ("RETR %s\r\n", path);
  code = ftp_line (cmd);
  if (code != 150 && code != 125)
    {
      delete
	s;
      s = 0;
      return;
    }
}

NetIO_FTP::~NetIO_FTP ()
{
  if (s)
    delete s;
}

int
NetIO_FTP::ok ()
{
  if (s && s->ok ())
    return 1;
  return 0;
}

ssize_t
NetIO_FTP::read (char *buf, size_t nbytes)
{
  ssize_t rv;
  if (!ok ())
    return 0;
  rv = s->read (buf, nbytes);
  if (rv == 0)
    ftp_line (cmd);
  return rv;
}
