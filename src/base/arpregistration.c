/******************************************************************************
 *
 * Project:  OSGeo4W
 * Purpose:  Register installation in Add/Remove Programs
 * Author:   Jürgen E. Fischer, jef@norbit.de
 *
 ******************************************************************************
 * Copyright (c) 2025, Jürgen E. Fischer, norBIT GmbH
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

#include <stdio.h>
#include <windows.h>

#define KEY_Uninstall "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall"

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

void createString(HKEY rkey, const char *valuename, const char *value)
{
    if ( RegSetValueEx(rkey, valuename, NULL, REG_SZ, value, strlen(value)) == ERROR_SUCCESS )
        return;

    fprintf( stderr, "could not set registry value for %s to %s.\n", valuename, value);
    exit( 6 );
}

/************************************************************************/
/*                                main()                                */
/************************************************************************/

int main( int argc, char **argv )
{
    char buf[2048];

    char *o4w_root = getenv("OSGEO4W_ROOT");
    if( !o4w_root )
    {
	fprintf(stderr, "OSGEO4W_ROOT not set.\n");
	exit( 1 );
    }

    const char *sysinstall = getenv("OSGEO4W_SYSTEM_INSTALL");
    HKEY hkey;
    if( sysinstall && strcmp(sysinstall, "1") == 0 )
    {
       hkey = HKEY_LOCAL_MACHINE;
    }
    else
    {
       hkey = HKEY_CURRENT_USER;
    }

    char guid[37];
    char guidfile[2048];
    snprintf(guidfile, sizeof guidfile, "%s\\etc\\setup\\arpuuid", o4w_root);

    FILE *fp = fopen(guidfile, "r");
    if( fp )
    {
	fgets(guid, sizeof guid-1, fp);
	guid[sizeof guid-1] = 0;
	fclose(fp);

	fprintf( stderr, "Already registered as %s.\n", guid );

	return 0;
    }

    UUID uuid;
    UuidCreate(&uuid);

    RPC_CSTR uuidstr;
    if( UuidToString(&uuid, &uuidstr) != RPC_S_OK)
    {
        fprintf( stderr, "could not convert uuid to string.\n" );
	return 2;
    }

    strcpy(guid, uuidstr);
    RpcStringFree(&uuidstr);

    char ukey[2048];
    snprintf(ukey, sizeof ukey, "%s\\{%s}", KEY_Uninstall, guid);

    HKEY rkey;
    DWORD disp;
    DWORD result = RegCreateKeyEx(hkey, ukey, 0, "", REG_OPTION_NON_VOLATILE, KEY_ALL_ACCESS, 0, &rkey, &disp);
    if(!rkey)
    {
        snprintf(buf, sizeof buf, "Could not create registry key %s [%d]", ukey, result);
        printWinError( buf, result );
	return 4;
    }

    if(disp == REG_OPENED_EXISTING_KEY)
    {
        fprintf( stderr, "registry key for %s already exists.\n", ukey );
        return 5;
    }

    snprintf(buf, sizeof buf, "OSGeo4W installation in %s", o4w_root);
    createString(rkey, "DisplayName", buf);

    snprintf(buf, sizeof buf, "%s\\bin\\osgeo4w-setup.exe", o4w_root);
    createString(rkey, "DisplayIcon", buf);

    createString(rkey, "InstallLocation", o4w_root);

    createString(rkey, "Publisher", "OSGeo Foundation");
    createString(rkey, "URLInfoAbout", "https://osgeo4w.osgeo.org");
    createString(rkey, "Contact", "osgeo4w-dev@lists.osgeo.org");

    snprintf(buf, sizeof buf, "\"%s\\bin\\osgeo4w-setup.exe\" -R \"%s\"", o4w_root, o4w_root);
    createString(rkey, "ModifyPath", buf);

    // Uninstall everything using the installer, remove start menu group and desktop directory and arp key
    char dirs[2048];
    snprintf(dirs, sizeof dirs, "\"%s\"", o4w_root);
    if( getenv("OSGEO4W_MENU_LINKS") && atoi( getenv("OSGEO4W_MENU_LINKS") ) && getenv("OSGEO4W_STARTMENU") )
        snprintf(dirs+strlen(dirs), sizeof dirs-strlen(dirs), " \"%s\"", getenv("OSGEO4W_STARTMENU") );
    if( getenv("OSGEO4W_DESKTOP_LINKS") && atoi( getenv("OSGEO4W_DESKTOP_LINKS") ) && getenv("OSGEO4W_DESKTOP") )
        snprintf(dirs+strlen(dirs), sizeof dirs-strlen(dirs), " \"%s\"", getenv("OSGEO4W_DESKTOP") );

    snprintf(buf, sizeof buf, "cmd /c start /min cmd /c \"\"%s\\bin\\osgeo4w-setup.exe\" -R \"%s\" -c All -q & rd /s /q %s & reg delete %s\\%s /f\"", o4w_root, o4w_root, dirs, hkey == HKEY_LOCAL_MACHINE ? "HKLM" : "HKCU", ukey);
    createString(rkey, "UninstallString", buf);

    fp = fopen(guidfile, "w");
    if(!fp) {
        fprintf( stderr, "could not create %s.\n", buf );
        return 3;
    }

    fputs(guid, fp);
    fclose(fp);


    return 0;
}
