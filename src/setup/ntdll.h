/*
 * Copyright (c) 2009, Red Hat, Inc.
 *
 *     This program is free software; you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation; either version 2 of the License, or
 *     (at your option) any later version.
 *
 *     A copy of the GNU General Public License can be found at
 *     http://www.gnu.org/
 *
 */

#ifndef SETUP_NTDLL_H
#define SETUP_NTDLL_H

#define NTOSAPI

#ifdef __MINGW64_VERSION_MAJOR
#include <winternl.h>
#include <ntdef.h>
#include <ntstatus.h>
#define DDKAPI __stdcall
#else
#include "ddk/ntapi.h"
#include "ddk/ntifs.h"
#endif

extern "C" {
NTSTATUS DDKAPI NtCreateFile (PHANDLE, ACCESS_MASK, POBJECT_ATTRIBUTES,
			      PIO_STATUS_BLOCK, PLARGE_INTEGER, ULONG, ULONG,
			      ULONG, ULONG, PVOID, ULONG);
NTSTATUS DDKAPI NtOpenFile (PHANDLE, ACCESS_MASK, POBJECT_ATTRIBUTES,
			    PIO_STATUS_BLOCK, ULONG, ULONG);
NTSTATUS DDKAPI NtClose (HANDLE);
NTSTATUS DDKAPI NtQueryAttributesFile (POBJECT_ATTRIBUTES,
				       PFILE_BASIC_INFORMATION);
NTSTATUS DDKAPI NtQueryInformationFile (HANDLE, PIO_STATUS_BLOCK, PVOID,
					ULONG, FILE_INFORMATION_CLASS);
NTSTATUS DDKAPI NtSetInformationFile (HANDLE, PIO_STATUS_BLOCK, PVOID, ULONG,
				      FILE_INFORMATION_CLASS);
ULONG NTAPI RtlNtStatusToDosError (NTSTATUS);
VOID NTAPI RtlInitUnicodeString (PUNICODE_STRING, PCWSTR);
};

#endif /* SETUP_NTDLL_H */
