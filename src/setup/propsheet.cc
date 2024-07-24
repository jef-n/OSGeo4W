/*
 * Copyright (c) 2001, 2002, 2003 Gary R. Van Sickle.
 *
 *     This program is free software; you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation; either version 2 of the License, or
 *     (at your option) any later version.
 *
 *     A copy of the GNU General Public License can be found at
 *     http://www.gnu.org/
 *
 * Written by Gary R. Van Sickle <g.r.vansickle@worldnet.att.net>
 *
 */

// This is the implementation of the PropSheet class.  This class encapsulates
// a Windows property sheet / wizard and interfaces with the PropertyPage class.
// It's named PropSheet instead of PropertySheet because the latter conflicts with
// the Windows function of the same name.

#include "propsheet.h"
#include "proppage.h"
#include "resource.h"
#include "RECTWrapper.h"
#include "ControlAdjuster.h"
#include "choose.h"
#include "Exception.h"
#include "resource.h"

#include <windows.h>
#include <shlwapi.h>

#ifndef PROPSHEETHEADER_V1_SIZE
#define PROPSHEETHEADER_V1_SIZE 40
#endif

// Sort of a "hidden" Windows structure.  Used in the PropSheetCallback.
#include <pshpack1.h>
typedef struct DLGTEMPLATEEX
{
  WORD dlgVer;
  WORD signature;
  DWORD helpID;
  DWORD exStyle;
  DWORD style;
  WORD cDlgItems;
  short x;
  short y;
  short cx;
  short cy;
}
DLGTEMPLATEEX, *LPDLGTEMPLATEEX;
#include <poppack.h>

PropSheet::PropSheet ()
{
}

PropSheet::~PropSheet ()
{
}

HPROPSHEETPAGE *
PropSheet::CreatePages ()
{
  HPROPSHEETPAGE *retarray;

  // Create the return array
  retarray = new HPROPSHEETPAGE[PropertyPages.size()];

  // Create the pages with CreatePropertySheetPage().
  // We do it here rather than in the PropertyPages themselves
  // because, for reasons known only to Microsoft, these handles will be
  // destroyed by the property sheet before the PropertySheet() call returns,
  // at least if it's modal (don't know about modeless).
  unsigned int i;
  for (i = 0; i < PropertyPages.size(); i++)
    {
      retarray[i] =
        CreatePropertySheetPage (PropertyPages[i]->GetPROPSHEETPAGEPtr ());

      if( !retarray[i] )
        {
          throw new Exception (__FUNCTION__,
                std::string( "Could not create property sheet page " ),
                APPERR_LOGIC_ERROR);
        }

      // Set position info
      if (i == 0)
        {
          PropertyPages[i]->YouAreFirst ();
        }
      else if (i == PropertyPages.size() - 1)
        {
          PropertyPages[i]->YouAreLast ();
        }
      else
        {
          PropertyPages[i]->YouAreMiddle ();
        }
    }

  return retarray;
}

// Stuff needed by the PropSheet wndproc hook
struct PropSheetData
{
  WNDPROC oldWndProc;
  bool clientRectValid;
  RECTWrapper lastClientRect;
  bool gotPage;
  RECTWrapper pageRect;
  bool hasMinRect;
  RECTWrapper minRect;

  PropSheetData ()
  {
    oldWndProc = 0;
    clientRectValid = false;
    gotPage = false;
    hasMinRect = false;
  }

// @@@ Ugly. Really only works because only one PS is used now.
  static PropSheetData& Instance()
  {
    static PropSheetData TheInstance;
    return TheInstance;
  }
};

static ControlAdjuster::ControlInfo PropSheetControlsInfo[] = {
  {0x3023, CP_RIGHT,   CP_BOTTOM},	// Back
  {0x3024, CP_RIGHT,   CP_BOTTOM},	// Next
  {0x3025, CP_RIGHT,   CP_BOTTOM},	// Finish
  {0x3026, CP_STRETCH, CP_BOTTOM},	// Line above buttons
  {	2, CP_RIGHT,   CP_BOTTOM},	// Cancel
  {0, CP_LEFT, CP_TOP}
};

static bool IsDialog (HWND hwnd)
{
  char className[7];
  GetClassName (hwnd, className, sizeof className);

  return (strcmp (className, "#32770") == 0);
}

BOOL CALLBACK EnumPages (HWND hwnd, LPARAM lParam)
{
  // Is it really a dialog?
  if (IsDialog (hwnd))
    {
      PropSheetData& psd = PropSheetData::Instance();
      SetWindowPos (hwnd, 0, psd.pageRect.left, psd.pageRect.top,
	psd.pageRect.width (), psd.pageRect.height (),
	SWP_NOACTIVATE | SWP_NOZORDER);
    }

  return TRUE;
}

static bool restoreWP = true;
static HWND dialogHWND = 0;


static LRESULT CALLBACK PropSheetWndProc (HWND hwnd, UINT uMsg,
  WPARAM wParam, LPARAM lParam)
{
  PropSheetData& psd = PropSheetData::Instance();
  switch (uMsg)
    {
    case WM_SHOWWINDOW:
      {
        if( hwnd != dialogHWND || !restoreWP )
	      break;

		restoreWP = false;

        const char *fg_ret = UserSettings::instance().get ("window-placement");
        if (!fg_ret)
            break;

        WINDOWPLACEMENT wp;
        char *buf = strdup( fg_ret );
        char *p = strtok( buf, "," );
        size_t i = 0;
        for( unsigned char *py = (unsigned char *) &wp;  p && i < sizeof (wp); i++, p = strtok (NULL, ",") )
          *py++ = atoi (p);
        free( buf );

        if( i == sizeof (wp) )
          {
            SetWindowPlacement(hwnd, &wp);
          }
      }
    case WM_DESTROY:
      {
		if( hwnd != dialogHWND )
		  break;

        WINDOWPLACEMENT wp;
        GetWindowPlacement (hwnd, &wp);

        std::string toset;
        unsigned char *p = (unsigned char *) &wp;
        for (size_t i = 0; i < sizeof (wp); i++)
          {
			if( i )
			  toset += ",";

			char number[4];
			sprintf( number, "%d", *p++ );

			toset += number;
          }
        UserSettings::instance().set ("window-placement", toset);
      }
      break;
  case WM_SYSCOMMAND:
  case WM_COMMAND:
      if (uMsg == WM_SYSCOMMAND && (wParam & 0xfff0) != SC_CLOSE)
          break;

      if (uMsg == WM_COMMAND && wParam != 2)
	      break;

      if (MessageBox(hwnd,
		     Window::loadRString(IDS_ABORT_WARNING).c_str(),
		     Window::loadRString(IDS_ABORT_CAPTION).c_str(),
                     MB_YESNO) == IDNO)
	      return 0;
      break;
    case WM_SIZE:
      {
        RECTWrapper clientRect;
        GetClientRect (hwnd, &clientRect);

        /*
           When the window is minimized, the client rect is reduced to
           (0,0-0,0), which causes child adjusting to screw slightly up. Work
           around by not adjusting child upon minimization - it isn't really
           needed then, anyway.
         */
        if (wParam != SIZE_MINIMIZED)
          {
            /*
               The first time we get a WM_SIZE, the client rect will be all zeros.
             */
            if (psd.clientRectValid)
              {
                const int dX =
                  clientRect.width () - psd.lastClientRect.width ();
                const int dY =
                  clientRect.height () - psd.lastClientRect.height ();

                ControlAdjuster::AdjustControls (hwnd, PropSheetControlsInfo,
                    dX, dY);

                psd.pageRect.right += dX;
                psd.pageRect.bottom += dY;

                /*
                   The pages are child windows, but don't have IDs.
                   So change them by enumerating all childs and adjust all
                   dialogs among them.
                 */
                if (psd.gotPage)
                  EnumChildWindows (hwnd, &EnumPages, 0);
              }
            else
              {
                psd.clientRectValid = true;
              }
            /*
               Store away the current size and use it as the minmal window size.
             */
            if (!psd.hasMinRect)
              {
                GetWindowRect (hwnd, &psd.minRect);
                psd.hasMinRect = true;
              }

            psd.lastClientRect = clientRect;
          }
      }
      break;
    case WM_GETMINMAXINFO:
      {
        if (psd.hasMinRect)
          {
            LPMINMAXINFO mmi = (LPMINMAXINFO)lParam;
            mmi->ptMinTrackSize.x = psd.minRect.width ();
            mmi->ptMinTrackSize.y = psd.minRect.height ();
          }
      }
      break;
    }

  return CallWindowProc (psd.oldWndProc,
    hwnd, uMsg, wParam, lParam);
}

static int CALLBACK
PropSheetProc (HWND hwndDlg, UINT uMsg, LPARAM lParam)
{
  switch (uMsg)
    {
    case PSCB_PRECREATE:
      {
        const LONG additionalStyle =
            (WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_THICKFRAME);
        // Add a minimize box to the sheet/wizard.
        if (((LPDLGTEMPLATEEX) lParam)->signature == 0xFFFF)
          {
            ((LPDLGTEMPLATEEX) lParam)->style |= additionalStyle;
          }
        else
          {
            ((LPDLGTEMPLATE) lParam)->style |= additionalStyle;
          }
      }
      return TRUE;
    case PSCB_INITIALIZED:
      {
        /*
          PropSheet() with PSH_USEICONID only sets the small icon,
          so we must set the big icon ourselves
        */
        SendMessage(hwndDlg, WM_SETICON, ICON_BIG, (LPARAM)LoadIcon(GetModuleHandle(NULL), MAKEINTRESOURCE(IDI_OSGEO4W)));
        /*
          Hook into the window proc.
          We need to catch some messages for resizing.
	     */
        PropSheetData::Instance().oldWndProc =
            (WNDPROC)GetWindowLongPtr (hwndDlg, GWLP_WNDPROC);
        SetWindowLongPtr (hwndDlg, GWLP_WNDPROC,
            (LONG_PTR)&PropSheetWndProc);
	    dialogHWND = hwndDlg;
      }
      return TRUE;
    }
  return TRUE;
}

static DWORD
GetPROPSHEETHEADERSize ()
{
  // For compatibility with all versions of comctl32.dll, we have to do this.
  DWORD retval = PROPSHEETHEADER_V1_SIZE;  // Something's wildly broken, punt.

  // This 'isn't safe' in a DLL, according to MSDN
  HMODULE mod = LoadLibrary ("comctl32.dll");

  DLLGETVERSIONPROC aDllGetVersion = (DLLGETVERSIONPROC) GetProcAddress (mod, "DllGetVersion");
  DLLVERSIONINFO vi = { sizeof (DLLVERSIONINFO), };

  if ( aDllGetVersion && SUCCEEDED( aDllGetVersion (&vi) ) && MAKELONG( vi.dwMinorVersion, vi.dwMajorVersion ) >= MAKELONG( 71, 4 ) )
    retval = sizeof (PROPSHEETHEADER);

  FreeLibrary (mod);

  return retval;
}

bool
PropSheet::Create (const Window * Parent, DWORD Style)
{
  PageHandles = CreatePages ();

  size_t sz = GetPROPSHEETHEADERSize();
  PROPSHEETHEADER p;
  memset(&p, 0, sz );
  p.dwSize      = (DWORD) sz;
  p.dwFlags     = PSH_NOAPPLYNOW | PSH_WIZARD | PSH_USECALLBACK /*| PSH_MODELESS */ | PSH_USEICONID;
  p.hwndParent  = Parent ? Parent->GetHWND () : NULL;
  p.hInstance   = GetInstance();
  p.nPages      = (UINT) PropertyPages.size();
  p.pszIcon     = MAKEINTRESOURCE(IDI_OSGEO4W);
  p.phpage      = PageHandles;
  p.pfnCallback = PropSheetProc;

  // The winmain event loop actually resides in here.
  PropertySheet (&p);

  SetHWND (NULL);

  return true;
}

void
PropSheet::SetHWNDFromPage (HWND h)
{
  // If we're a modal dialog, there's no way for us to know our window handle unless
  // one of our pages tells us through this function.
  SetHWND (h);
}

/*
  Adjust the size of a page so that it fits nicely into the window.
 */
void
PropSheet::AdjustPageSize (HWND page)
{
  PropSheetData& psd = PropSheetData::Instance();
  if (!psd.clientRectValid) return;

  /*
    It's probably not obvious what's done here:
    When this method is called the first time, the first page is already
    created and sized, but at the coordinates (0,0). The sheet, however,
    isn't in it's final size. My guess is that the sheet first creates the
    page, and then resizes itself to have the right metrics to contain the
    page and moves it to it's position. For our purposes, however, we need
    the final metrics of the page. So, the first time this method is called,
    we basically grab the size of the page, but calculate the top/left coords
    ourselves.
   */

  if (!psd.gotPage)
    {
      psd.gotPage = true;

      RECTWrapper& pageRect = psd.pageRect;
      ::GetWindowRect (page, &pageRect);
      // We want client coords.
      ::ScreenToClient (page, (LPPOINT)&pageRect.left);
      ::ScreenToClient (page, (LPPOINT)&pageRect.right);

      LONG dialogBaseUnits = ::GetDialogBaseUnits ();
      // The margins in DUs are a result of "educated guesses" and T&E.
      int marginX = MulDiv (5, LOWORD(dialogBaseUnits), 4);
      int marginY = MulDiv (5, HIWORD(dialogBaseUnits), 8);

      pageRect.move (marginX, marginY);
    }

  SetWindowPos (page, 0, psd.pageRect.left, psd.pageRect.top,
    psd.pageRect.width (), psd.pageRect.height (),
    SWP_NOACTIVATE | SWP_NOZORDER);
}

void
PropSheet::AddPage (PropertyPage * p)
{
  // Add a page to the property sheet.
  p->YouAreBeingAddedToASheet (this);
  PropertyPages.push_back(p);
}

bool
PropSheet::SetActivePage (int i)
{
  // Posts a message to the message queue, so this won't block
  return PropSheet_SetCurSel (GetHWND (), NULL, i) != 0;
}

bool
PropSheet::SetActivePageByID (int resource_id)
{
  // Posts a message to the message queue, so this won't block
  return PropSheet_SetCurSelByID (GetHWND (), resource_id) != 0;
}

void
PropSheet::SetButtons (DWORD flags)
{
  // Posts a message to the message queue, so this won't block
  PropSheet_SetWizButtons (GetHWND (), flags);
}

void
PropSheet::PressButton (int button)
{
  PropSheet_PressButton (GetHWND (), button);
}

int PropSheet::pageno( HWND hwnd )
{
  for( int i = 0; PropertyPages.size(); i++ )
  {
	  if( PropertyPages[i]->GetHWND() == hwnd )
	    return i;
  }
  return -1;
}
