#include <stdlib.h>
#include <wchar.h>
#include "win32.h"
#include "shlobj.h"
#include "mklink2.h"
#include "filemanip.h"
#include "Window.h"
#include <vector>

/* This part of the code must be in C because the C++ interface to COM
doesn't work. */

/* Initialized in WinMain.  This is required under Windows 7.  If
   CoCreateInstance gets called from here, it fails to create the
   instance with an undocumented error code 0x80110474.
   FIXME: I have no idea why this happens. */
IShellLink *sl;

extern "C"
void
make_link_2 (char const *exepath, char const *args, char const *icon, char const *lname)
{
  IPersistFile *pf;
  WCHAR widepath[MAX_PATH];
  if (sl)
    {
      sl->QueryInterface (IID_IPersistFile, (void **) &pf);

      sl->SetPath (exepath);
      sl->SetArguments (args);
      sl->SetIconLocation (icon, 0);

      MultiByteToWideChar (CP_ACP, 0, lname, -1, widepath, MAX_PATH);
      pf->Save (widepath, TRUE);

      pf->Release ();
    }
}

#define SYMLINK_COOKIE "!<symlink>"

/* Predicate: file is not currently in existence.
 * A file race can occur otherwise.
 */
extern "C"
int
mkcygsymlink (const char *from, const char *to)
{
  unsigned long w;
  HANDLE h = CreateFileA (from, GENERIC_WRITE, 0, 0, CREATE_NEW,
		          FILE_ATTRIBUTE_NORMAL | FILE_FLAG_BACKUP_SEMANTICS, 0);
  if (h == INVALID_HANDLE_VALUE)
    return 1;

  std::string buf = Window::sprintf( "%s%s", SYMLINK_COOKIE, to );
  if (WriteFile (h, buf.c_str(), (DWORD) buf.size() + 1, &w, NULL))
    {
      CloseHandle (h);
      SetFileAttributesA (from, FILE_ATTRIBUTE_SYSTEM);
      return 0;
    }
  CloseHandle (h);
  DeleteFileA (from);
  return 1;
}

extern "C"
int
mkcyghardlink (const char *from, const char *to)
{
  return CreateHardLinkA( to, from, 0 );
}
