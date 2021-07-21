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

/* The purpose of this file is to provide common functionality for
   all the dialogs in the program. */

#include "win32.h"
#include <stdio.h>
#include <stdlib.h>
#include "dialog.h"
#include "msg.h"
#include "LogSingleton.h"
#include "mount.h"

char *
eget (HWND h, int id, char *var)
{
  char tmp[4000];
  if (var && var != get_root_dir ().c_str())
    {
      delete [] var;
      var = NULL;
    }
  if (GetDlgItemText (h, id, tmp, sizeof tmp) > 0)
    {
      var = new char [strlen (tmp) + 1];
      var [strlen (tmp)] = '\0';
      strcpy (var, tmp);
    }
  return var;
}

std::string
egetString (HWND h, int id)
{
  std::string aString;
  char tmp[4000];
  if (GetDlgItemText (h, id, tmp, sizeof tmp) > 0)
    aString = std::string (tmp);
  return aString;
}

int
eget (HWND h, int id)
{
  BOOL s;
  int r = GetDlgItemInt (h, id, &s, TRUE);
  return r;
}

void
eset (HWND h, int id, const char *val)
{
  SetDlgItemText (h, id, val);
}

void
eset (HWND h, int id, const std::string aString)
{
  SetDlgItemText (h, id, aString.c_str());
}

void
eset (HWND h, int id, int val)
{
  SetDlgItemInt (h, id, (UINT) val, TRUE);
}

int
rbget (HWND h, int *ids)
{
  int i;
  for (i = 0; ids[i]; i++)
    if (IsDlgButtonChecked (h, ids[i]) == BST_CHECKED)
      return ids[i];
  return 0;
}

void
rbset (HWND h, int *ids, int id)
{
  int i;
  for (i = 0; ids[i]; i++)
    CheckDlgButton (h, ids[i], id == ids[i] ? BST_CHECKED : BST_UNCHECKED);
}

void
fatal (const char *msg, DWORD err)
{
  DWORD e = (err != ERROR_SUCCESS) ? err : GetLastError();
  char *buf;
  FormatMessage (FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM,
		 0, e, 0, (CHAR *) & buf, 0, 0);
  MessageBox (0, buf, msg, 0);
  LogSingleton::GetInstance().exit (1);
  // Keep gcc happy - some sort of bug!
  exit (1);
}
