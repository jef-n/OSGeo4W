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

#define WIN32_LEAN_AND_MEAN
#include <windows.h>

typedef struct {
  const char *name;
  HINSTANCE handle;
} DllInfo;

#define DLL(n) __attribute__ ((used)) static DllInfo n ## _info __asm__ (#n "_info") = { #n, 0}

#define Auto(dll, func, size) \
	__asm__ ("\t.data"); \
	__asm__ ("\t.global\t_" #func "@" #size); \
	__asm__ ("_" #func "@" #size ":"); \
	__asm__ ("\tcall\tautoload_common"); \
	__asm__ ("\t.long\t" #dll "_info"); \
	__asm__ ("\t.ascii\t\"" #func "\\0\"")

DLL (wininet);

Auto (wininet, InternetAttemptConnect, 4);
Auto (wininet, InternetCloseHandle, 4);
Auto (wininet, InternetGetLastResponseInfoA, 12);
Auto (wininet, InternetOpenA, 20);
Auto (wininet, InternetOpenUrlA, 24);
Auto (wininet, InternetReadFile, 16);
Auto (wininet, InternetSetOptionA, 16);
Auto (wininet, InternetQueryOptionA, 16);
Auto (wininet, HttpQueryInfoA, 20);
Auto (wininet, HttpSendRequestA, 20);

DLL (advapi32);

Auto (advapi32, AddAccessAllowedAce, 16);
Auto (advapi32, AllocateAndInitializeSid, 44);
Auto (advapi32, FreeSid, 4);
Auto (advapi32, InitializeAcl, 12);
Auto (advapi32, OpenProcessToken, 12);
Auto (advapi32, SetTokenInformation, 16);
Auto (advapi32, OpenSCManagerA, 16);
Auto (advapi32, CloseServiceHandle, 4);
Auto (advapi32, OpenServiceA, 16);
Auto (advapi32, QueryServiceStatus, 8);
Auto (advapi32, StartServiceA, 16);


typedef struct {
  DllInfo *dll;
  char name[100];
} AutoEntry;

__attribute__ ((used)) static void autoload_common (int x) __asm__ ("autoload_common");

static void
autoload_common (int x)
{
  int fp, rel;
  unsigned char *proc;
  HINSTANCE h;
  AutoEntry *a;

  a = *(AutoEntry **)(&x - 1);
  if (a->dll->handle == 0)
    {
      h = LoadLibrary (a->dll->name);
      a->dll->handle = h;
    }
  fp = (int) GetProcAddress (a->dll->handle, a->name);
  proc = ((unsigned char *)a) - 5;
  rel = fp - (int)(a); /* now it's a relative call */
  *proc++ = 0xe9; /* jump near 32-bit relative */
  *proc++ = rel;
  *proc++ = rel>>8;
  *proc++ = rel>>16;
  *proc++ = rel>>24;

  *(int *)(&x-1) = (int)proc-5;
}
