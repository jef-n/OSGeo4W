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

#ifndef SETUP_DIALOG_H
#define SETUP_DIALOG_H

#if defined(__GNUC__)
#define NORETURN __attribute__ ((noreturn))
#elif defined(_MSC_VER)
#define NORETURN __declspec(noreturn)
#else
#define NORETURN
#endif

#include <string>

#include "win32.h"

/* global instance for the application; set in main.cc */
extern HINSTANCE hinstance;

/* used by main.cc to select the next do_* function */
extern int next_dialog;

/* either "nothing to do" or "setup complete" or something like that */
extern int exit_msg;

#define D(x) void x(HINSTANCE _h, HWND owner)

/* prototypes for all the do_* functions (most called by main.cc) */

D (do_download);
bool do_fromcwd(HINSTANCE _h, HWND owner);
D (do_ini);
D (do_install);
D (do_postinstall);
D (do_prereq_check);
D (do_license);
#undef D

/* Get the value of an EditText control.  Pass the previously stored
   value and it will free the memory if needed. */

char *eget (HWND h, int id, char *var);

/* Get the value of an EditText control. */

std::string egetString (HWND h, int id);

/* Same, but convert the value to an integer */

int eget (HWND h, int id);

/* Set the EditText control to the given value */

void eset (HWND h, int id, const char *var);
void eset (HWND h, int id, const std::string);
void eset (HWND h, int id, int var);

/* RadioButtons.  ids is a null-terminated list of IDs.  Get
   returns the selected ID (or zero), pass an ID to set */

int rbget (HWND h, int *ids);
void rbset (HWND h, int *ids, int id);

/* *This* version of fatal (compare with msg.h) uses GetLastError() to
   format a suitable error message.  Similar to perror() */

NORETURN void fatal (const char *msg, DWORD err = ERROR_SUCCESS);

#endif /* SETUP_DIALOG_H */
