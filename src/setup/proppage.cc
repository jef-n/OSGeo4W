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

// This is the implementation of the PropertyPage class.  It works closely with the
// PropSheet class to implement a single page of the property sheet.

#include "proppage.h"
#include "propsheet.h"
#include "win32.h"
#include <shellapi.h>
#include "resource.h"
#include "state.h"

#include "getopt++/BoolOption.h"
#include "Exception.h"
#include "LogSingleton.h"

bool PropertyPage::DoOnceForSheet = true;

/*
  Sizing information for some controls that are common to all pages.
 */
static ControlAdjuster::ControlInfo DefaultControlsInfo[] = {
  {IDC_HEADICON,      CP_RIGHT,   CP_TOP},
  {IDC_HEADSEPARATOR, CP_STRETCH, CP_TOP},
  {0, CP_LEFT, CP_TOP}
};

PropertyPage::PropertyPage ()
{
  proc = NULL;
  cmdproc = NULL;
  IsFirst = false;
  IsLast = false;

  sizeProcessor.AddControlInfo (DefaultControlsInfo);
}

PropertyPage::~PropertyPage ()
{
}

bool PropertyPage::Create (int TemplateID)
{
  if( !Create (NULL, NULL, TemplateID) )
  {
	  throw new Exception (__FUNCTION__,
                         std::string( "Could not create property page " ),
                         APPERR_LOGIC_ERROR);
  }

  return true;
}

bool PropertyPage::Create (DLGPROC dlgproc, int TemplateID)
{
  return Create (dlgproc, NULL, TemplateID);
}

bool
PropertyPage::Create (DLGPROC dlgproc,
                      BOOL (*cproc) (HWND h, int id, HWND hwndctl,
                      UINT code), int TemplateID)
{
  psp = new PROPSHEETPAGE();
  memset( psp, 0, sizeof psp );
  psp->dwSize = sizeof (PROPSHEETPAGE);
  psp->dwFlags = 0;
  psp->hInstance = GetInstance ();
  psp->pfnDlgProc = FirstDialogProcReflector;
  psp->pszTemplate = MAKEINTRESOURCE(TemplateID);
  psp->lParam = (LPARAM) this;
  psp->pfnCallback = NULL;

  proc = dlgproc;
  cmdproc = cproc;

  return true;
}

INT_PTR CALLBACK
PropertyPage::FirstDialogProcReflector (HWND hwnd, UINT message,
					WPARAM wParam, LPARAM lParam)
{
  PropertyPage *This;

  if (message != WM_INITDIALOG)
    {
      // Don't handle anything until we get a WM_INITDIALOG message, which
      // will have our 'this' pointer with it.
      return FALSE;
    }

  This = (PropertyPage *) (((PROPSHEETPAGE *) lParam)->lParam);

  SetWindowLongPtr (hwnd, DWLP_USER, (LONG_PTR) This);
  SetWindowLongPtr (hwnd, DWLP_DLGPROC, (LONG_PTR) DialogProcReflector);

  This->SetHWND (hwnd);
  return This->DialogProc (message, wParam, lParam);
}

INT_PTR CALLBACK
PropertyPage::DialogProcReflector (HWND hwnd, UINT message,
                                   WPARAM wParam, LPARAM lParam)
{
  PropertyPage *This = (PropertyPage *) GetWindowLongPtr (hwnd, DWLP_USER);
  return This->DialogProc (message, wParam, lParam);
}

INT_PTR CALLBACK
PropertyPage::DialogProc (UINT message, WPARAM wParam, LPARAM lParam)
{
  try
  {
    if (proc != NULL)
    {
      proc (GetHWND (), message, wParam, lParam);
    }

    switch (message)
    {
      case WM_INITDIALOG:
        {
          OnInit ();

          setTitleFont ();

          // Call it here so it stores the initial client rect.
          sizeProcessor.UpdateSize (GetHWND ());

          // TRUE = Set focus to default control (in wParam).
          return TRUE;
        }
      case WM_NOTIFY:
        switch (((NMHDR FAR *) lParam)->code)
        {
          case PSN_APPLY:
            {
              SetWindowLongPtr (GetHWND (), DWLP_MSGRESULT, PSNRET_NOERROR);
              return TRUE;
            }
          case PSN_SETACTIVE:
            {
              if (DoOnceForSheet)
              {
                // Tell our parent PropSheet what its own HWND is.
                GetOwner ()->SetHWNDFromPage (((NMHDR FAR *) lParam)->
                                              hwndFrom);
                GetOwner ()->CenterWindow ();
                DoOnceForSheet = false;
              }

              GetOwner ()->AdjustPageSize (GetHWND ());

              // Set the wizard buttons appropriately
              if (IsFirst)
              {
                // Disable "Back" on first page.
                GetOwner ()->SetButtons (PSWIZB_NEXT);
              }
              else if (IsLast)
              {
                // Disable "Next", enable "Finish" on last page
                GetOwner ()->SetButtons (PSWIZB_BACK | PSWIZB_FINISH);
              }
              else
              {
                // Middle page, enable both "Next" and "Back" buttons
                GetOwner ()->SetButtons (PSWIZB_BACK | PSWIZB_NEXT);
              }

              if(!wantsActivation())
              {
                ::SetWindowLongPtr (GetHWND (), DWLP_MSGRESULT, -1);
                return TRUE;
              }

              OnActivate ();

              if (unattended_mode)
              {
                // -2 == disable unattended mode, display page
                // -1 == display page but stay in unattended mode (progress bars)
                // 0 == skip to next page (in propsheet sequence)
                // IDD_* == skip to specified page
                long nextwindow = OnUnattended();
                if (nextwindow == -2)
                {
                  unattended_mode = attended;
                  SetWindowLongPtr (GetHWND (), DWLP_MSGRESULT, 0);
                  return TRUE;
                }
                else if (nextwindow == -1)
                {
                  SetWindowLongPtr (GetHWND (), DWLP_MSGRESULT, 0);
                  return TRUE;
                }
                else if (nextwindow == 0)
                {
                  SetWindowLongPtr (GetHWND (), DWLP_MSGRESULT, -1);
                  return TRUE;
                }
                else
                {
                  SetWindowLongPtr (GetHWND (), DWLP_MSGRESULT, nextwindow);
                  return TRUE;
                }
              }
              else
              {
                // 0 == Accept activation, -1 = Don't accept
                ::SetWindowLongPtr (GetHWND (), DWLP_MSGRESULT, 0);
                return TRUE;
              }

            }
            break;
          case PSN_KILLACTIVE:
            {
              OnDeactivate ();
              // FALSE = Allow deactivation
              SetWindowLongPtr (GetHWND (), DWLP_MSGRESULT, FALSE);
              return TRUE;
            }
          case PSN_WIZNEXT:
            {
              LONG retval;
              retval = OnNext ();
              SetWindowLongPtr (GetHWND (), DWLP_MSGRESULT, retval);
              return TRUE;
            }
          case PSN_WIZBACK:
            {
              LONG retval;
              retval = OnBack ();
              SetWindowLongPtr (GetHWND (), DWLP_MSGRESULT, retval);
              return TRUE;
            }
          case PSN_WIZFINISH:
            {
              OnFinish ();
              // False = Allow the wizard to finish
              SetWindowLongPtr (GetHWND (), DWLP_MSGRESULT, FALSE);
              return TRUE;
            }
          case TTN_GETDISPINFO:
            {
              return TooltipNotificationHandler (lParam);
            }
          default:
            {
              // Unrecognized notification
              return FALSE;
            }
        }
        break;
      case WM_COMMAND:
        {
          bool retval =
            OnMessageCmd (LOWORD (wParam), (HWND) lParam, HIWORD (wParam));
          if (retval)
          {
            // Handled, return 0
            SetWindowLongPtr (GetHWND (), DWLP_MSGRESULT, 0);
            return TRUE;
          }
          else if (cmdproc != NULL)
          {
            cmdproc (GetHWND(), LOWORD(wParam), (HWND)lParam, HIWORD(wParam));
            return 0;
          }
          break;
        }
      case WM_SIZE:
        {
          sizeProcessor.UpdateSize (GetHWND ());
          break;
        }
      case WM_CTLCOLORSTATIC:
        {
          // check for text controls that we've url-ified that are initializing
          int id;
          std::map <int, ClickableURL>::iterator theURL;

          // get the ID of the control, and look it up in our list
          if ((id = GetDlgCtrlID ((HWND)lParam)) == 0 ||
               (theURL = urls.find (id)) == urls.end ())

            // nope sorry, don't know nothing about this control
            return FALSE;

          // set FG = blue, BG = default background for a dialog
          SetTextColor ((HDC)wParam, RGB (0, 0, 255));
          SetBkColor ((HDC)wParam, GetSysColor (COLOR_BTNFACE));

          // get the current font, add underline, and set it back
          if (theURL->second.font == 0)
            {
              TEXTMETRIC tm;

              GetTextMetrics ((HDC)wParam, &tm);
              LOGFONT lf;
              memset (&lf, 0, sizeof (LOGFONT));
              lf.lfUnderline = TRUE;
              lf.lfHeight = tm.tmHeight;
              lf.lfWeight = tm.tmWeight;
              lf.lfItalic = tm.tmItalic;
              lf.lfStrikeOut = tm.tmStruckOut;
              lf.lfCharSet = tm.tmCharSet;
              lf.lfOutPrecision = OUT_DEFAULT_PRECIS;
              lf.lfClipPrecision = CLIP_DEFAULT_PRECIS;
              lf.lfQuality = DEFAULT_QUALITY;
              lf.lfPitchAndFamily = tm.tmPitchAndFamily;
              GetTextFace ((HDC)wParam, LF_FACESIZE, lf.lfFaceName);
              if ((theURL->second.font = CreateFontIndirect (&lf)) == NULL)
                log(LOG_PLAIN) << "Warning: unable to set font for url "
                    << theURL->second.url << endLog;
            }

          // apply the font
          SelectObject ((HDC)wParam, theURL->second.font);

          // make a brush if we have not yet
          if (theURL->second.brush == NULL)
              theURL->second.brush = CreateSolidBrush
                                            (GetSysColor (COLOR_BTNFACE));

          return (INT_PTR) theURL->second.brush;
        }
      case WM_MOUSEWHEEL:
        // we do this so that derived classes that wish to process this message
        // do not need to reimplement the entire WinProc, they can just
        // provide an OnMouseWheel.  (Note that mousewheel events are delivered
        // to the parent of the window that received the scroll, so it would
        // not work to just process this message there.)
        return OnMouseWheel (message, wParam, lParam);
        break;
      default:
        break;
    }

    if ((message >= WM_APP) && (message < 0xC000))
    {
      // It's a private app message
      return OnMessageApp (message, wParam, lParam);
    }
  }
  TOPLEVEL_CATCH("DialogProc");

  // Wasn't handled
  return FALSE;
}

INT_PTR CALLBACK
PropertyPage::OnMouseWheel (UINT message, WPARAM wParam, LPARAM lParam)
{
  return 1; // not handled; define in a derived class to support this
}

void
PropertyPage::setTitleFont ()
{
  // These font settings will just silently fail when the resource id
  // is not present on a page.
  // Set header title font of each internal page
  SetDlgItemFont(IDC_STATIC_HEADER_TITLE, "MS Shell Dlg", 8, FW_BOLD);
  // Set the font for the IDC_STATIC_WELCOME_TITLE
  SetDlgItemFont(IDC_STATIC_WELCOME_TITLE, "Arial", 12, FW_BOLD);
}

std::map <int, PropertyPage::ClickableURL> PropertyPage::urls;

void
PropertyPage::makeClickable (int id, std::string link)
// turns a static text control in this dialog into a hyperlink
{
  // get the handle of the specified control
  HWND hctl = ::GetDlgItem (GetHWND (), id);
  if (hctl == NULL)
    return;           // invalid ID

  if (urls.find (id) != urls.end ())
    return;           // already done this one

  ClickableURL c;
  c.url = link;
  c.font = NULL;      // these will be created as needed
  c.brush = NULL;
  if ((c.origWinProc = reinterpret_cast<WNDPROC>(SetWindowLongPtr (hctl,
          GWLP_WNDPROC, (LONG_PTR) & PropertyPage::urlWinProc))) == 0)
    return;           // failure

  // add this to 'urls' so that the dialog and control winprocs know about it
  urls[id] = c;

  // set a tooltip for the link
  AddTooltip (id, link.c_str());
}

LRESULT CALLBACK
PropertyPage::urlWinProc (HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
// a winproc that we use to subclass a static text control to make a URL
{
  int id;
  std::map <int, ClickableURL>::iterator theURL;

  // get the ID of the control, and look it up in our list
  if ((id = GetDlgCtrlID (hwnd)) == 0 ||
       (theURL = urls.find (id)) == urls.end ())

    // we were called for a control that we weren't installed on
    // punt to default winproc
    return DefWindowProc (hwnd, uMsg, wParam, lParam);

  switch (uMsg)
  {
    case WM_LBUTTONDOWN:
      {
        // they clicked our URL!  yay!
        intptr_t rc = (intptr_t) ShellExecute (hwnd, "open",
            theURL->second.url.c_str (), NULL, NULL, SW_SHOWNORMAL);

        if (rc <= 32)
          log(LOG_PLAIN) << "Unable to launch browser for URL " <<
              theURL->second.url << " (rc = " << rc << ")" << endLog;
        break;
      }
    case WM_SETCURSOR:
      {
        // show the hand cursor when they hover
        // note: apparently the hand cursor isn't available
        // on very old versions of win95?  So, check return of LoadCursor
        // and don't attempt SetCursor if it failed
        HCURSOR c = LoadCursor (NULL, reinterpret_cast<LPCSTR>(IDC_HAND));
        if (c)
          SetCursor (c);
        return TRUE;
      }
    case WM_NCHITTEST:
      {
        // normally, a static control returns HTTRANSPARENT for this
        // which means that we would never receive the SETCURSOR message
        return HTCLIENT;
      }
    case WM_DESTROY:
      {
        // clean up
        WNDPROC saveWinProc = theURL->second.origWinProc;
        DeleteObject (theURL->second.font);
        DeleteObject (theURL->second.brush);
        urls.erase (id);
        return CallWindowProc (saveWinProc, hwnd, uMsg, wParam, lParam);
      }
  }

  // pass on control to the previous winproc
  return CallWindowProc (theURL->second.origWinProc, hwnd, uMsg, wParam, lParam);
}
