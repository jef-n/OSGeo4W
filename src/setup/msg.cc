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

/* The purpose of this file is to centralize all the message
   functions. */

#if 0
static const char *cvsid =
  "\n%%% $Id: msg.cc,v 2.9 2008/08/07 22:59:17 davek Exp $\n";
#endif

#include "msg.h"

#include "LogSingleton.h"
#include "win32.h"

#include <stdio.h>
#include <stdarg.h>
#include <vector>
#include "dialog.h"
#include "state.h"

void
msg (const char *fmt, ...)
{
  va_list args;
  va_start (args, fmt);

  int len = vsnprintf (0, 0, fmt, args);

  std::vector<char> buf( len + 2 );
  vsnprintf (buf.data(), len+1, fmt, args);
  OutputDebugString (buf.data());
}

static int
mbox (HWND owner, const char *name, int type, int id, va_list args)
{
  char buf[1000], fmt[1000];

  if (LoadString (hinstance, id, fmt, sizeof fmt) <= 0)
    ExitProcess (0);

  vsnprintf (buf, 1000, fmt, args);
  log (LOG_PLAIN) << "mbox " << name << ": " << buf << endLog;
  if (unattended_mode != attended)
    {
      // Return some default values.
      log (LOG_PLAIN) << "unattended_mode is set at mbox: returning default value" << endLog;
      switch (type & MB_TYPEMASK)
	{
	  case MB_OK:
	  case MB_OKCANCEL:
	    return IDOK;
	    break;
	  case MB_YESNO:
	  case MB_YESNOCANCEL:
	    return IDYES;
	    break;
	  case MB_ABORTRETRYIGNORE:
	    return IDIGNORE;
	    break;
	  case MB_RETRYCANCEL:
	    return IDCANCEL;
	    break;
	  default:
	    log (LOG_PLAIN) << "unattended_mode failed for " << (type & MB_TYPEMASK) << endLog;
	    return 0;
	}
    }
  return MessageBox (owner, buf, "OSGeo4W Setup", type);
}

void
note (HWND owner, int id, ...)
{
  va_list args;
  va_start (args, id);
  mbox (owner, "note", 0, id, args);
}

void
fatal (HWND owner, int id, ...)
{
  va_list args;
  va_start (args, id);
  mbox (owner, "fatal", 0, id, args);
  LogSingleton::GetInstance().exit (1);
}

int
yesno (HWND owner, int id, ...)
{
  va_list args;
  va_start (args, id);
  return mbox (owner, "yesno", MB_YESNO, id, args);
}
