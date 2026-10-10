/******************************************************************************
 *
 * Project:  OSGeo4W
 * Purpose:  Register or remove security catalog
 * Author:   Jürgen E. Fischer, jef@norbit.de
 *
 ******************************************************************************
 * Copyright (c) 2026, Jürgen E. Fischer, norBIT GmbH
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
#include <mscat.h>
#include <stdio.h>
#include <string.h>

#define ARRAY_SIZE(x) (sizeof x/sizeof *x)

/************************************************************************/
/*                       printWinError()                                */
/************************************************************************/

void printWinError(const wchar_t *msg, DWORD dwError)
{
    LPWSTR lpMsgBuf;
    FormatMessageW( FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM |  FORMAT_MESSAGE_IGNORE_INSERTS, NULL, dwError, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), (LPWSTR) &lpMsgBuf, 0, NULL );
    lpMsgBuf[ wcslen(lpMsgBuf)-1 ] = '\0';
    fwprintf( stderr, L"%s\n%d: %s\n", msg, dwError, lpMsgBuf);
    LocalFree( lpMsgBuf );
}

/************************************************************************/
/*                       usage()                                        */
/************************************************************************/

void usage()
{
    fwprintf(stderr, L"Usage: catregistration.exe {-a|-r} catalog.cat\n  Add/remove security catalog");
}

/************************************************************************/
/*                       wmain()                                        */
/************************************************************************/

int wmain(int argc, wchar_t* argv[])
{
    wchar_t buf[MAX_PATH];
    int res = 0;

    if (argc < 3) {
        usage();
        return 1;
    }

    const wchar_t *opt = argv[1];
    const wchar_t *catPath = argv[2];

    BOOL add;
    if (wcscmp(opt, L"-a") == 0) {
        add = TRUE;
    } else if (wcscmp(opt, L"-r") == 0) {
        add = FALSE;
    } else {
        fwprintf(stderr, L"Unexpected option\n");
	usage();
        return 1;
    }

    HCATADMIN hCatAdmin = NULL;
    if (!CryptCATAdminAcquireContext(&hCatAdmin, NULL, 0)) {
        printWinError(L"CryptCATAdminAcquireContext failed", GetLastError());
        return 1;
    }

    wchar_t addedCatalog[MAX_PATH];
    *addedCatalog = 0;

    wchar_t recordPath[MAX_PATH];
    _snwprintf(recordPath, ARRAY_SIZE(recordPath), L"%s.added", catPath);

    FILE *fp = _wfopen(recordPath, L"r");
    if( fp ) {
        if( !fgetws(addedCatalog, ARRAY_SIZE(addedCatalog), fp) )
            fwprintf(stderr, L"Could not read recorded catalog for %s\n", catPath);
	fclose(fp);
    }

    if( add && !*addedCatalog ) {
        HCATINFO hCatInfo = CryptCATAdminAddCatalog(hCatAdmin, (PWSTR) catPath, NULL, 0);
        if (hCatInfo) {
            CATALOG_INFO ci;
            ci.cbStruct = sizeof ci;

            if( CryptCATCatalogInfoFromContext(hCatInfo, &ci, 0) ) {
                wprintf(L"Catalog %s registered as %s\n", catPath, ci.wszCatalogFile);

                fp = _wfopen(recordPath, L"w");
                if( fp ) {
		    const wchar_t *n = wcsrchr(ci.wszCatalogFile, L'\\');
		    fputws(n ? n+1 : ci.wszCatalogFile, fp);
                    fclose(fp);
                } else {
                    _snwprintf(buf, ARRAY_SIZE(buf), L"Could not save registered catalog %s for %s to %s\n", ci.wszCatalogFile, catPath, recordPath);
                    printWinError(buf, GetLastError());
                    res = 4;
                }
            } else {
                _snwprintf(buf, ARRAY_SIZE(buf), L"Could not retrieve catalog info for %s", catPath);
                printWinError(buf, GetLastError());
                res = 3;
            }

            CryptCATAdminReleaseCatalogContext(hCatAdmin, hCatInfo, 0);
        } else {
           _snwprintf(buf, ARRAY_SIZE(buf), L"Adding catalog %s failed", catPath);
           printWinError(buf, GetLastError());
           res = 2;
        }
    } else if( add ) {
        fwprintf(stderr, L"Catalog %s already registered as %s\n", catPath, addedCatalog);
    } else if( *addedCatalog ) {
        SetLastError(0);
        if ( CryptCATAdminRemoveCatalog(hCatAdmin, addedCatalog, 0) && GetLastError() == 0 ) {
            wprintf(L"Catalog %s for %s unregistered\n", addedCatalog, catPath);
	    if( _wunlink(recordPath) ) {
	        _snwprintf(buf, ARRAY_SIZE(buf), L"Could not remove catalog record %s", recordPath);
	        printWinError(buf, GetLastError());
	        res = 6;
	    }
        } else {
	    _snwprintf(buf, ARRAY_SIZE(buf), L"Could not removed recorded catalog %s for %s", addedCatalog, catPath);
	    printWinError(buf, GetLastError());
	    res = 5;
	}
    } else {
        fwprintf(stderr, L"No record of catalog %s", catPath);
        res = 7;
    }

    CryptCATAdminReleaseContext(hCatAdmin, 0);

    return res;
}
