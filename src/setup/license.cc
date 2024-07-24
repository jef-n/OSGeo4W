/*
  This is the implementation of the LicensePage class.
*/
#include <stdio.h>
#include "setup_version.h"
#include "dialog.h"
#include "resource.h"
#include "license.h"
#include "state.h"
#include "getopt++/GetOption.h"
#include "getopt++/BoolOption.h"
#include "propsheet.h"

#include "package_db.h"
#include "package_meta.h"
#include "package_version.h"
#include "package_source.h"
#include "threebar.h"
#include "io_stream.h"
#include "msg.h"

#include <string>
#include <winspool.h>
#include <commDlg.h>
#include <windows.h>
#include <richedit.h>

using namespace std;

BoolOption AutoAcceptLicenseOption(false, 'k', "autoaccept", "Accept all licenses");

extern ThreeBarProgressPage Progress;

static ControlAdjuster::ControlInfo LicenseControlsInfo[] = {
  { IDC_STATIC_LICENSE_TEXT, CP_STRETCH, CP_TOP },
  { IDC_LICENSE_FILE, CP_STRETCH, CP_STRETCH },
  { IDC_PRINT_BUTTON, CP_RIGHT, CP_BOTTOM },
  { IDC_CHK_AGREED, CP_LEFT, CP_BOTTOM },
  { 0, CP_LEFT, CP_TOP }
};

LicensePage::LicensePage ()
{
  sizeProcessor.AddControlInfo (LicenseControlsInfo);
}

bool
LicensePage::Create ()
{
  return PropertyPage::Create (IDD_LICENSE);
}

void
LicensePage::OnInit ()
{
  ins_pkgname = GetDlgItem (IDC_STATIC_LICENSE_TEXT);
  ins_licensetxt = GetDlgItem (IDC_LICENSE_FILE);
}

void
LicensePage::OnActivate()
{
  CheckDlgButton ( GetHWND(), IDC_CHK_AGREED, BST_UNCHECKED );

  currentLicense.clear();

  string packages;
  string localpath;

  // find first package with unaccepted license and the packages it applies to
  packagedb db;
  for (packagedb::packagecollection::iterator i = db.packages.begin (); i != db.packages.end() && currentLicense.empty(); ++i)
    {
      packagemeta & pkg = *(i->second);

      // skip not picked packages
      if ( !pkg.desired.picked() && !pkg.desired.sourcePackage().picked() )
        continue;

      // skip already installed packages
      if ( pkg.installed && pkg.desired == pkg.installed )
        continue;

      for(multimap <string, RestrictivePackage *>::iterator it = packagedb::blacklist.begin();
          it != packagedb::blacklist.end() && currentLicense.empty();
          it = packagedb::blacklist.upper_bound( it->first ) )
        {
          // iterate packages that have the same license
          pair< multimap<string, RestrictivePackage *>::iterator,
                multimap<string, RestrictivePackage *>::iterator  > range = packagedb::blacklist.equal_range( it->first );
          for( multimap<string, RestrictivePackage *>::iterator it2 = range.first; it2 != range.second; ++it2 )
            {
              RestrictivePackage &rp = *it2->second;

              if( rp.agree_license || rp.local_path.empty() || pkg.name!=rp.name || pkg.desired.Canonical_version() != rp.version )
                continue;

              rp.selectedpkg = true;

              if( packages.empty() )
                {
                  currentLicense = it->first;
                  packages = pkg.SDesc() + " (" + rp.name + ")";
                  localpath = rp.local_path;
                }
              else
                {
                  packages += ", " + pkg.SDesc() + " (" + rp.name + ")";
                }
            }
        }
    }

  if( !packages.empty() )
    {
      setPackageName( sprintf( loadRString( IDS_CAPTION_LIC_PACKAGE ).c_str(), packages.c_str() ).c_str() );

      if( !loadLicense(localpath) )
        {
          log (LOG_PLAIN) << "Installer couldn't find a license at " << localpath << ". Please make sure it is installed." << endLog;
        }
      else
        {
          log (LOG_PLAIN) << "License " << localpath << " successfully loaded." << endLog;
        }

      UpdateWindow( GetHWND() );
    }
}

long LicensePage::OnBack()
{
  currentLicense.clear ();
  return IDD_CHOOSE;
}

long
LicensePage::OnNext()
{
  if( !currentLicense.empty() )
    {
      pair< multimap<string, RestrictivePackage *>::iterator,
            multimap<string, RestrictivePackage *>::iterator  > range = packagedb::blacklist.equal_range( currentLicense );

      bool checked = IsDlgButtonChecked ( GetHWND(), IDC_CHK_AGREED) == BST_CHECKED;

      for( multimap<string, RestrictivePackage *>::iterator it = range.first; it != range.second; ++it )
        {
          it->second->agree_license = checked;
          if( checked && it->second->selectedpkg )
            {
              log(LOG_BABBLE) << "license " << it->second->name << " accepted [" << currentLicense << "]" << endLog;
            }
          }
    }

  for( multimap <string, RestrictivePackage *>::iterator it = packagedb::blacklist.begin(); it != packagedb::blacklist.end(); it++ )
    {
      if ( it->second->selectedpkg && !it->second->agree_license )
        {
          log(LOG_BABBLE) << "You must agree to the licenses of all restrictive packages that you chose. " << it->second->name << " not accepted." << endLog;
          return IDD_LICENSE;
        }
    }

  log(LOG_BABBLE) << "All restrictive packages were accepted" << endLog;
  Progress.SetActivateTask (WM_APP_START_DOWNLOAD);
  return IDD_INSTATUS;
}

void LicensePage::setPackageName(const TCHAR * t)
{
  ::SetWindowText (ins_pkgname, t);
}

void LicensePage::setLicenseText(const std::string &t )
{
  ::SetWindowText( ins_licensetxt, t.c_str() );
  ::SendMessage( ins_licensetxt, EM_SETSEL, -1, 0 );
  ::SendMessage( ins_licensetxt, WM_VSCROLL, SB_TOP, 0 );
}

void LicensePage::updateButtonNext()
{
  DWORD ButtonFlags = PSWIZB_BACK;

  if( IsDlgButtonChecked ( GetHWND(), IDC_CHK_AGREED) == BST_CHECKED )
    ButtonFlags |= PSWIZB_NEXT;

  GetOwner()->SetButtons( ButtonFlags );
}

bool LicensePage::wantsActivation() const
{
  packagedb db;
  int package_number = 0, rpackage_selected = 0, rpackage_accepted = 0;
  for (packagedb::packagecollection::iterator i = db.packages.begin (); i != db.packages.end (); ++i)
  {
    packagemeta & pkg = *(i->second);

#if 0
    if (pkg.HasLicense())
      log (LOG_BABBLE) << pkg.name << " has a license agreement, you will need to accept it it is in " << pkg.PathLicense() << endLog;
#endif

    if ( !pkg.desired.picked() && !pkg.desired.sourcePackage().picked() )
      continue;

    if ( pkg.installed && pkg.desired == pkg.installed )
      continue;

    for( multimap<string, RestrictivePackage *>::iterator it = packagedb::blacklist.begin(); it != packagedb::blacklist.end(); ++it)
    {
      RestrictivePackage & rp = *it->second;

      if(rp.name == pkg.name && rp.version == pkg.desired.Canonical_version())
      {
        rp.selectedpkg = true;
        rpackage_selected++;
        if( rp.agree_license )
          rpackage_accepted++;
        log (LOG_BABBLE)
          << rpackage_selected << ": restricted package " << rp.name << "-" << rp.version
          << " [" << it->first
          << ", " << (rp.agree_license ? "accepted" : "not yet accepted")
          << "]" << endLog;
      }
    }

    package_number++;
  }

  log (LOG_BABBLE) << package_number << " packages selected, "
                   << rpackage_selected << " restricted selected, "
                   << rpackage_accepted << " accepted."
                   << endLog;

  if( rpackage_selected > rpackage_accepted )
    {
      Progress.SetActivateTask (WM_APP_START_LICENSE_FILE_DOWNLOAD);
      return true;
    }
  else
    {
      Progress.SetActivateTask (WM_APP_START_DOWNLOAD);
      return false;
    }
}

bool LicensePage::OnMessageCmd (int id, HWND hwndctl, UINT code)
{
  switch (id)
  {
    case IDC_PRINT_BUTTON:
      printLicense(hwndctl);
      return true;

    case IDC_CHK_AGREED:
    case IDC_LICENSE_FILE:
      updateButtonNext();
      return true;

    default:
      break;
  }

  return false;
}

bool LicensePage::loadLicense(std::string pfile)
{
  io_stream *file = io_stream::open(pfile, "rt");
  if(!file)
    return false;

  string text;

  bool first = true;
  char buff[1024];
  while( file->gets( buff, sizeof buff) )
  {
    if( first && !*buff )
      continue;
    text.append( buff ).append( "\r\n" );
    first = false;
  }

  setLicenseText( text );

  return true;
}

/* Obtain printer device context */
HDC LicensePage::getPrinterDC(HWND Hwnd)
{
  PRINTDLG pdlg = { sizeof(PRINTDLG) };

  // Initialize the PRINTDLG structure.
  pdlg.hwndOwner = Hwnd;
  // Set the flag to return printer DC.
  pdlg.Flags = PD_RETURNDC;

  // Invoke the printer dialog box.
  if( !::PrintDlg( &pdlg ) )
    return 0;

  // hDC member of the PRINTDLG structure contains
  return pdlg.hDC;
}

void LicensePage::printLicense( HWND hWndParent )
{
  HDC hDC = getPrinterDC(hWndParent);
  if(!hDC)
    return;

  // http://msdn.microsoft.com/en-us/library/windows/desktop/bb787875%28v=vs.85%29.aspx

  DOCINFO di = { sizeof(di) };
  if (!StartDoc(hDC, &di))
    return;

  int pw = GetDeviceCaps(hDC, PHYSICALWIDTH);
  int ph = GetDeviceCaps(hDC, PHYSICALHEIGHT);

  int dpi_x = GetDeviceCaps(hDC, LOGPIXELSX);
  int dpi_y = GetDeviceCaps(hDC, LOGPIXELSY);

  FORMATRANGE fr;
  fr.hdc       = hDC;
  fr.hdcTarget = hDC;

  // Set page rect to physical page size in twips.
  fr.rcPage.top    = 0;
  fr.rcPage.left   = 0;
  fr.rcPage.right  = MulDiv(pw, 1440, dpi_x );
  fr.rcPage.bottom = MulDiv(ph, 1440, dpi_y );

  // Set the rendering rectangle to the printable area of the page.
  fr.rc.left       = MulDiv( fr.rcPage.right, 1, 10 );
  fr.rc.right      = MulDiv( fr.rcPage.right, 9, 10 );
  fr.rc.top        = MulDiv( fr.rcPage.bottom, 1, 20 );
  fr.rc.bottom     = MulDiv( fr.rcPage.bottom, 19, 20 );

  SendMessage(ins_licensetxt, EM_SETSEL, 0, (LPARAM)-1);          // Select the entire contents.
  SendMessage(ins_licensetxt, EM_EXGETSEL, 0, (LPARAM)&fr.chrg);  // Get the selection into a CHARRANGE.

  bool fSuccess = true;

  // Use GDI to print successive pages.
  while (fr.chrg.cpMin < fr.chrg.cpMax && fSuccess)
  {
    fSuccess = StartPage(hDC) > 0;
    if (!fSuccess)
    {
      break;
    }

    LRESULT cpMin = SendMessage(ins_licensetxt, EM_FORMATRANGE, TRUE, (LPARAM)&fr);
    if (cpMin <= fr.chrg.cpMin)
    {
      fSuccess = false;
      break;
    }

    fr.chrg.cpMin = (LONG) cpMin;
    fSuccess = EndPage(hDC) > 0;
  }

  SendMessage(ins_licensetxt, EM_FORMATRANGE, FALSE, 0);

  if (fSuccess)
  {
    EndDoc(hDC);
  }
  else
  {
    AbortDoc(hDC);
  }
}

long LicensePage::OnUnattended()
{
  if( AutoAcceptLicenseOption )
  {
    CheckDlgButton( GetHWND(), IDC_CHK_AGREED, BST_CHECKED );
    OnNext();
    return 0;
  }

  return -2;
}
