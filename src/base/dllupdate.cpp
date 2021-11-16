/******************************************************************************
 *
 * Project:  OSGeo4W
 * Purpose:  Update DLLs in windows\system32 if we have newer version.
 * Author:   Frank Warmerdam, warmerdam@pobox.com
 *
 ******************************************************************************
 * Copyright (c) 2009, Frank Warmerdam
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 ****************************************************************************/

#include <windows.h>
#include <stdio.h>

#define KEY_SharedDlls "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\SharedDLLs"

static void GetDLLVersion( char *pszDLLPath,
                           __int64 &version,
                           bool &bExists, bool &bHasVersionInfo );
static void refSharedDLL( char *pszDLLPath );
static void unrefSharedDLL( char *pszDLLPath );
static void notifyReboot( bool bQuiet );
static void Usage();
static void printWinError( char *msg, DWORD dwError );

/************************************************************************/
/*                                main()                                */
/************************************************************************/

int main( int argc, char **argv )
{
    bool bQuiet = false;
    bool bOnlyIfTargetExists = false;
    bool bDoCopy = false;
    bool bNotifyReboot = false;
    bool bUnref = false;
    char *pszSourceDLL = NULL;
    char *pszTargetDir = NULL;
    char szTargetDLL[2048] = "";
    char msg[2048] = "";
    int  i;

    /* -------------------------------------------------------------------- */
    /*      Process arguments.                                              */
    /* -------------------------------------------------------------------- */
    if( argc < 2 )
	Usage();

    for( i = 1; i < argc; i++ )
    {
	if( strcmp(argv[i],"-q") == 0 )
	    bQuiet = true;

	else if( strcmp(argv[i],"-oite") == 0 )
	    bOnlyIfTargetExists = true;

	else if( strcmp(argv[i],"-copy") == 0 )
	    bDoCopy = true;

	else if( strcmp(argv[i],"-reboot") == 0 )
	    bNotifyReboot = true;

	else if( strcmp(argv[i],"-unref") == 0 )
	    bUnref = true;

	else if( argv[i][0] == '-' )
	    Usage();

	else if( pszSourceDLL == NULL )
	    pszSourceDLL = argv[i];

	else if( pszTargetDir == NULL )
	    pszTargetDir = argv[i];

	else
	    Usage();
    }

    if( pszSourceDLL == NULL || (bUnref && bDoCopy) )
	Usage();

    /* -------------------------------------------------------------------- */
    /*      Use default target directory if one is not specified.           */
    /* -------------------------------------------------------------------- */
    if( pszTargetDir == NULL )
    {
	if( getenv("WINDIR") != NULL )
	{
	    static char szSystem32[2048];

	    sprintf( szSystem32, "%s\\system32", getenv("WINDIR") );
	    pszTargetDir = szSystem32;
	}
	else
	    pszTargetDir = "C:\\windows\\system32";
    }

    /* -------------------------------------------------------------------- */
    /*      Get version info on source DLL.                                 */
    /* -------------------------------------------------------------------- */
    __int64 nSourceVersion = 0;
    bool    bExists, bHasVersionInfo;

    GetDLLVersion( pszSourceDLL, nSourceVersion, bExists, bHasVersionInfo );

    if( !bExists )
    {
	fprintf( stderr, "%s does not exist.\n", pszSourceDLL );
	exit( 1 );
    }

    if( !bHasVersionInfo )
    {
	fprintf( stderr, "%s has no version info.\n", pszSourceDLL );
	exit( 1 );
    }

    if( !bQuiet )
	printf( "%s: Version=%d.%d.%d.%d\n",
		pszSourceDLL,
		(int) ((nSourceVersion >> 48) & 0xffff),
		(int) ((nSourceVersion >> 32) & 0xffff),
		(int) ((nSourceVersion >> 16) & 0xffff),
		(int) ((nSourceVersion >> 0) & 0xffff) );

    /* -------------------------------------------------------------------- */
    /*      Construct the name of the destination DLL.                      */
    /* -------------------------------------------------------------------- */
    const char *pszBase;

    for( i = strlen(pszSourceDLL)-1; i > 0; i-- )
    {
	if( pszSourceDLL[i] == '/'
		|| pszSourceDLL[i] == '\\'
		|| pszSourceDLL[i] == ':' )
	{
	    i++;
	    break;
	}
    }

    sprintf( szTargetDLL, "%s\\%s", pszTargetDir, pszSourceDLL+i );

    if( bUnref )
    {
	unrefSharedDLL( szTargetDLL );
	if( bNotifyReboot )
	    notifyReboot(bQuiet);
	exit(0);
    }

    /* -------------------------------------------------------------------- */
    /*      Get info on the target DLL.                                     */
    /* -------------------------------------------------------------------- */
    __int64 nTargetVersion = 0;

    GetDLLVersion( szTargetDLL, nTargetVersion, bExists, bHasVersionInfo );

    if( !bQuiet )
	printf( "%s: Version=%d.%d.%d.%d\n",
		szTargetDLL,
		(int) ((nTargetVersion >> 48) & 0xffff),
		(int) ((nTargetVersion >> 32) & 0xffff),
		(int) ((nTargetVersion >> 16) & 0xffff),
		(int) ((nTargetVersion >> 0) & 0xffff) );

    if( !bDoCopy )
	exit( 0 );

    refSharedDLL(szTargetDLL);

    /* -------------------------------------------------------------------- */
    /*      Do we want to update?                                           */
    /* -------------------------------------------------------------------- */
    if( !bExists && bOnlyIfTargetExists )
    {
	if( !bQuiet )
	    printf( "Target does not exist, no action.\n" );
	exit( 0 );
    }

    if( nTargetVersion >= nSourceVersion )
    {
	if( !bQuiet )
	    printf( "Target is not older than source, no action.\n" );
	exit( 0 );
    }

    /* -------------------------------------------------------------------- */
    /*      Try to copy the file directly.                                  */
    /* -------------------------------------------------------------------- */
    if( CopyFile( pszSourceDLL, szTargetDLL, FALSE ) )
    {
	if( !bQuiet )
	    printf( "Copied %s to %s successfully.\n",
		    pszSourceDLL, szTargetDLL );

	exit( 0 );
    }

    /* -------------------------------------------------------------------- */
    /*      If that failed, we are presumably replacing an "in use" DLL.    */
    /*      Copy to a .new version and schedule for renaming on reboot.     */
    /* -------------------------------------------------------------------- */
    char szTempTargetDLL[2048];

    sprintf( szTempTargetDLL, "%s.new", szTargetDLL );

    if( CopyFile( pszSourceDLL, szTempTargetDLL, FALSE ) )
    {
	if (!MoveFileEx( szTempTargetDLL, szTargetDLL,
		    MOVEFILE_DELAY_UNTIL_REBOOT |
		    MOVEFILE_REPLACE_EXISTING))
	{
	    sprintf( msg,
		    "Target file %s is busy/unwritable, and attempt to\n"
		    "schedule %s to be renamed on reboot have failed.",
		    szTargetDLL, szTempTargetDLL );

	    printWinError( msg, GetLastError() );

	    exit( 1 );
	}

	if( !bQuiet )
	{
	    printf( "Target file %s is busy/unwritable, file written to\n"
		    "%s, and will be renamed on reboot.\n",
		    szTargetDLL, szTempTargetDLL );
	}

	if( bNotifyReboot )
	    notifyReboot(bQuiet);

	exit( 0 );
    }

    sprintf( msg,
	    "Target file %s is busy/unwritable, and attempt to copy\n"
	    "to temporary file %s has failed.",
	    szTargetDLL, szTempTargetDLL );
    printWinError( msg, GetLastError() );

    exit( 1 );
}

/************************************************************************/
/*                               Usage()                                */
/************************************************************************/

static void Usage()
{
    printf( "\n"
	    "Usage: dllupdate.exe [-q] [-oite] [-copy] [-unref] source_dll [target_directory]\n"
	    "\n"
	    " -q: quiet\n"
	    " -oite: only copy if target dll exists\n"
	    " -copy: enable copy/update (default is info only)\n"
	    " -reboot: create %%OSGEO4W_ROOT%%/etc/reboot if the update needs a reboot\n"
	    " -unref: decrement reference count and remove target dll if 0\n"
	    " source_dll: The full path to the source dll\n"
	    " target_directory: path to target dir, default is %%WINDIR%%\\system32\n" );
    exit( 1 );
}

/************************************************************************/
/*                           GetDLLVersion()                            */
/************************************************************************/

static void GetDLLVersion( char *pszDLLPath,
                           __int64 &version,
                           bool &bExists, bool &bHasVersionInfo )
{
    DWORD dwLen, dwUseless, dwBufSize;
    LPTSTR lpVI;
    VS_FIXEDFILEINFO* lpFFI;
    FILE *fp;

    bExists = false;
    bHasVersionInfo = false;

    if( (fp = fopen(pszDLLPath,"rb")) == NULL )
	return;

    bExists = true;
    fclose( fp );

    dwLen = GetFileVersionInfoSize( pszDLLPath, &dwUseless );

    if( dwLen == 0 )
	return;

    lpVI = (LPSTR) malloc(dwLen);
    if( !GetFileVersionInfo( pszDLLPath, NULL, dwLen, lpVI ) )
	return;

    if( !VerQueryValue( lpVI, "\\", (LPVOID *) &lpFFI, (UINT *) &dwUseless ) )
	return;

    bHasVersionInfo = true;

    version = lpFFI->dwProductVersionMS;
    version = version << 32;
    version |= lpFFI->dwProductVersionLS;

    free( lpVI );
}

/************************************************************************/
/*                           refSharedDLL()                             */
/************************************************************************/

static void refSharedDLL( char *pszDLLPath )
{
    char msg[2048];
    HKEY rkey;
    DWORD disp;
    DWORD result = RegCreateKeyEx(HKEY_LOCAL_MACHINE, KEY_SharedDlls, 0, "", REG_OPTION_NON_VOLATILE, KEY_ALL_ACCESS, 0, &rkey, &disp);
    if(rkey)
    {
	DWORD dwType;
	int refcount = 0;
	DWORD cbData = sizeof(refcount);
	result = RegQueryValueEx(rkey, pszDLLPath, NULL, &dwType, (LPBYTE) &refcount, &cbData);

	refcount++;

	result = RegSetValueEx(rkey, pszDLLPath, NULL, REG_DWORD, (LPBYTE) &refcount, sizeof(refcount));
	if(result != ERROR_SUCCESS)
	{
	    sprintf( msg, "Could not set %s in %s", pszDLLPath, KEY_SharedDlls );
	    printWinError( msg, result );
	}

	RegCloseKey(rkey);
    }
    else
    {
	sprintf( msg, "Could not open %s", KEY_SharedDlls, result );
	printWinError( msg, result );
    }
}

/************************************************************************/
/*                           unrefSharedDLL()                           */
/************************************************************************/

static void unrefSharedDLL( char *pszDLLPath )
{
    char msg[2048];
    bool bFound = false;
    int refcount = 0;
    HKEY rkey = 0;
    DWORD disp;
    DWORD result = RegCreateKeyEx(HKEY_LOCAL_MACHINE, KEY_SharedDlls, 0, "", REG_OPTION_NON_VOLATILE, KEY_ALL_ACCESS, 0, &rkey, &disp);

    if(rkey)
    {
	DWORD dwType;
	DWORD cbData = sizeof(refcount);
	result = RegQueryValueEx(rkey, pszDLLPath, NULL, &dwType, (LPBYTE) &refcount, &cbData);
        if( result == ERROR_SUCCESS )
	    bFound = true;
	else
	{
	    sprintf( msg, "Value %s not found in %s", pszDLLPath, KEY_SharedDlls );
	    printWinError( msg, result );
	}
    }
    else
    {
	sprintf( msg, "Could not open %s", KEY_SharedDlls, result );
	printWinError( msg, result );
    }

    if(--refcount<=0)
    {
	if( !DeleteFile(pszDLLPath) && !MoveFileEx( pszDLLPath, NULL, MOVEFILE_DELAY_UNTIL_REBOOT ) )
	{
	    sprintf( msg,
		    "File %s is busy/undeletable, and attempt to\n"
		    "schedule it's removal on reboot has failed.",
		    pszDLLPath );
	    printWinError( msg, GetLastError() );
	}

	if( bFound && rkey )
	{
	    result = RegDeleteValue(rkey, pszDLLPath);
	    if( result != ERROR_SUCCESS )
	    {
	        sprintf( msg, "Could not remove %s from %s", pszDLLPath, KEY_SharedDlls );
		printWinError( msg, result );
	    }
	}
    }

    if(refcount>0 && rkey)
    {
	result = RegSetValueEx(rkey, pszDLLPath, NULL, REG_DWORD, (LPBYTE) &refcount, sizeof(refcount));
	if( result != ERROR_SUCCESS )
	{
	    sprintf( msg, "Could not set %s in %s", pszDLLPath, KEY_SharedDlls );
	    printWinError( msg, result );
	}
    }

    if(rkey)
	RegCloseKey(rkey);
}

/************************************************************************/
/*                           notifyReboot()                             */
/************************************************************************/

static void notifyReboot(bool bQuiet)
{
    char *pszDir = getenv("OSGEO4W_ROOT");
    if( pszDir )
    {
	char szEtcReboot[2048];
	FILE *fp;

	sprintf(szEtcReboot, "%s\\etc\\reboot", pszDir);
	fp = fopen(szEtcReboot, "w");
	if( !fp )
	{
	    fprintf( stderr, "Could not create file %s\n", szEtcReboot );
	    exit( 1 );
	}

	fclose(fp);
    }
    else
    {
	fprintf( stderr, "Environment variable OSGEO4W_ROOT not set\n" );
	exit(1);
    }

    if( !bQuiet )
    {
	printf( "Installer was notified that a reboot is due.\n" );
    }
}

/************************************************************************/
/*                       printWinError()                                */
/************************************************************************/

void printWinError(char *msg, DWORD dwError)
{
    LPSTR lpMsgBuf;
    FormatMessage( FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM |  FORMAT_MESSAGE_IGNORE_INSERTS, NULL, dwError, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), (LPSTR) &lpMsgBuf, 0, NULL );
    lpMsgBuf[ strlen(lpMsgBuf)-1 ] = '\0';
    fprintf( stderr, "%s\n%d: %s\n", msg, dwError, lpMsgBuf);
    LocalFree( lpMsgBuf );
}

/* vim: set sw=4 : */
