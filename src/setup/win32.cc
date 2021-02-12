/*
 * Copyright (c) 2007 Brian Dessent
 *
 *     This program is free software; you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation; either version 2 of the License, or
 *     (at your option) any later version.
 *
 *     A copy of the GNU General Public License can be found at
 *     http://www.gnu.org/
 *
 * Written by Brian Dessent <brian@dessent.net>
 *
 */

#if 0
static const char *cvsid =
  "\n%%% $Id: win32.cc,v 2.3 2007/02/28 00:55:04 briand Exp $\n";
#endif

#include <malloc.h>
#include <sys/stat.h>
#include <memory>
#include "win32.h"
#include "state.h"
#include "LogFile.h"



void
TokenGroupCollection::populate ()
{
  if (!GetTokenInformation (token.theHANDLE(), TokenGroups, buffer,
                            bufferSize, &bufferSize))
    {
      log (LOG_TIMESTAMP) << "GetTokenInformation() failed: " <<
	  	GetLastError () << endLog;
	return;
    }
  populated_ = true;
}

bool
TokenGroupCollection::find (SIDWrapper const &aSID) const
{
  if (!populated ())
    return false;
  TOKEN_GROUPS *groups = (TOKEN_GROUPS *) buffer;
  for (DWORD pg = 0; pg < groups->GroupCount; ++pg)
    if (EqualSid (groups->Groups[pg].Sid, aSID.theSID ()))
      return true;
  return false;
}

void
NTSecurity::NoteFailedAPI (const std::string &api)
{
  log (LOG_TIMESTAMP) << api << "() failed: " << GetLastError () << endLog;
}

void
NTSecurity::initialiseEveryOneSID ()
{
  SID_IDENTIFIER_AUTHORITY sid_auth = { SECURITY_WORLD_SID_AUTHORITY };
  if (!AllocateAndInitializeSid (&sid_auth, 1, 0, 0, 0, 0, 0, 0, 0, 0,
                                 &everyOneSID.theSID ()))
    {
      NoteFailedAPI ("AllocateAndInitializeSid");
      failed (true);
    }
}

void
NTSecurity::setDefaultDACL ()
{
  /* To assure that the created files have a useful ACL, the 
     default DACL in the process token is set to full access to
     everyone. This applies to files and subdirectories created
     in directories which don't propagate permissions to child
     objects. 
     To assure that the files group is meaningful, a token primary
     group of None is changed to Users or Administrators.  */

  initialiseEveryOneSID ();
  if (failed ())
    return;

  /* Create a buffer which has enough room to contain the TOKEN_DEFAULT_DACL
     structure plus an ACL with one ACE.  */
  size_t bufferSize = sizeof (ACL) + sizeof (ACCESS_ALLOWED_ACE)
                      + GetLengthSid (everyOneSID.theSID ()) - sizeof (DWORD);

  std::auto_ptr<char> buf (new char[bufferSize]);

  /* First initialize the TOKEN_DEFAULT_DACL structure.  */
  PACL dacl = (PACL) buf.get ();

  /* Initialize the ACL for containing one ACE.  */
  if (!InitializeAcl (dacl, (DWORD) bufferSize, ACL_REVISION))
    {
      NoteFailedAPI ("InitializeAcl");
      failed (true);
      return;
    }

  /* Create the ACE which grants full access to "Everyone" and store it
     in dacl.  */
  if (!AddAccessAllowedAce
      (dacl, ACL_REVISION, GENERIC_ALL, everyOneSID.theSID ()))
    {
      NoteFailedAPI ("AddAccessAllowedAce");
      failed (true);
      return;
    }

  /* Get the processes access token. */
  if (!OpenProcessToken (GetCurrentProcess (),
                        TOKEN_READ | TOKEN_ADJUST_DEFAULT, &token.theHANDLE ()))
    {
      NoteFailedAPI ("OpenProcessToken");
      failed (true);
      return;
    }

  /* Set the default DACL to the above computed ACL. */
  if (!SetTokenInformation (token.theHANDLE(), TokenDefaultDacl, &dacl, 
                            (DWORD) bufferSize))
    {
      NoteFailedAPI ("SetTokenInformation");
      failed (true);
    }
}

void
NTSecurity::setDefaultSecurity ()
{
  if( safe_mode )
      return;

  setDefaultDACL ();
  if (failed ())
    return;

  /* Get the user */
  if (!GetTokenInformation (token.theHANDLE (), TokenUser, &osid, 
			    sizeof osid, &size))
    {
      NoteFailedAPI ("GetTokenInformation");
      return;
    }
  /* Make it the owner */
  if (!SetTokenInformation (token.theHANDLE (), TokenOwner, &osid, 
			    sizeof osid))
    {
      NoteFailedAPI ("SetTokenInformation");
      return;
    }

  SID_IDENTIFIER_AUTHORITY sid_auth = { SECURITY_NT_AUTHORITY, };
  /* Get the SID for "Administrators" S-1-5-32-544 */
  if (!AllocateAndInitializeSid (&sid_auth, 2, SECURITY_BUILTIN_DOMAIN_RID, 
				 DOMAIN_ALIAS_RID_ADMINS, 0, 0, 0, 0, 0, 0,
				 &administratorsSID.theSID ()))
    {
      NoteFailedAPI ("AllocateAndInitializeSid");
      return;
    }
  /* Get the SID for "Users" S-1-5-32-545 */
  if (!AllocateAndInitializeSid (&sid_auth, 2, SECURITY_BUILTIN_DOMAIN_RID, 
			DOMAIN_ALIAS_RID_USERS, 0, 0, 0, 0, 0, 0,
			&usid.theSID ()))
    {
      NoteFailedAPI ("AllocateAndInitializeSid");
      return;
    }
  /* Get the token groups */
  if (!GetTokenInformation (token.theHANDLE(), TokenGroups, NULL, 0, &size)
	  && GetLastError () != ERROR_INSUFFICIENT_BUFFER)
    {
      NoteFailedAPI("GetTokenInformation");
      return;
    }
  TokenGroupCollection ntGroups(size, token);
  ntGroups.populate ();
  if (!ntGroups.populated ())
    return;
  /* Set the default group to one of the above computed SID.  */
  PSID nsid = NULL;
  if (ntGroups.find (usid))
    {
      nsid = usid.theSID ();
      log (LOG_TIMESTAMP) << "Changing gid to Users" << endLog;
    }
  else if (ntGroups.find (administratorsSID))
    {
      nsid = administratorsSID.theSID ();
      log (LOG_TIMESTAMP) << "Changing gid to Administrators" << endLog;
    }
  if (nsid && !SetTokenInformation (token.theHANDLE (), TokenPrimaryGroup,
                                    &nsid, sizeof nsid))
    NoteFailedAPI ("SetTokenInformation");
}

VersionInfo::VersionInfo ()
{
  v.dwOSVersionInfoSize = sizeof (OSVERSIONINFO);
  if (GetVersionEx (&v) == 0)
    {
      log (LOG_PLAIN) << "GetVersionEx () failed: " << GetLastError () 
                      << endLog;
      
      /* If GetVersionEx fails we really should bail with an error of some kind,
         but for now just assume we're on NT and continue.  */
      v.dwPlatformId = VER_PLATFORM_WIN32_NT;
    }
}

/* This is the Construct on First Use idiom to avoid static initialization
   order problems.  */
VersionInfo& GetVer ()
{
  static VersionInfo *vi = new VersionInfo ();
  return *vi;
}
