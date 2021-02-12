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

// This is the implementation of the Window class.  It serves both as a window class
// in its own right and as a base class for other window-like classes (e.g. PropertyPage,
// PropSheet).

#include "win32.h"
#include "window.h"
#include "RECTWrapper.h"
#include "msg.h"
#include "resource.h"
#include "stdio.h"
#include <iterator>

ATOM Window::WindowClassAtom = 0;
HINSTANCE Window::AppInstance = NULL;

Window::Window ()
{
  WindowHandle = NULL;
  Parent = NULL;
  TooltipHandle = NULL;
  BusyCount = 0;
  BusyCursor = NULL;

}

Window::~Window ()
{
  // Delete any fonts we created.
  for (unsigned int i = 0; i < Fonts.size (); i++)
    DeleteObject (Fonts[i]);

  // shut down the tooltip control, if activated
  if (TooltipHandle)
    DestroyWindow (TooltipHandle);

  // FIXME: Maybe do some reference counting and do this Unregister
  // when there are no more of us left.  Not real critical unless
  // we're in a DLL which we're not right now.
  //UnregisterClass(WindowClassAtom, InstanceHandle);
}

LRESULT CALLBACK
Window::FirstWindowProcReflector (HWND hwnd, UINT uMsg, WPARAM wParam,
				  LPARAM lParam)
{
  Window *wnd = NULL;

  if(uMsg == WM_NCCREATE)
    {
      // This is the first message a window gets (so MSDN says anyway).
      // Take this opportunity to "link" the HWND to the 'this' ptr, steering
      // messages to the class instance's WindowProc().
      wnd = reinterpret_cast<Window *>(((LPCREATESTRUCT)lParam)->lpCreateParams);

      // Set a backreference to this class instance in the HWND.
      SetWindowLongPtr (hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(wnd));

      // Set a new WindowProc now that we have the peliminaries done.
      // We could instead simply do the contents of Window::WindowProcReflector
      // in the 'else' clause below, but this way we eliminate an unnecessary 'if/else' on
      // every message.  Yeah, it's probably not worth the trouble.
      SetWindowLongPtr (hwnd, GWLP_WNDPROC, (LONG_PTR) & Window::WindowProcReflector);
      // Finally, store the window handle in the class.
      wnd->WindowHandle = hwnd;
    }
  else
    {
      // Should never get here.
      fatal(NULL, IDS_WINDOW_INIT_BADMSG, uMsg);
    }

  return wnd->WindowProc (uMsg, wParam, lParam);
}

LRESULT CALLBACK
Window::WindowProcReflector (HWND hwnd, UINT uMsg, WPARAM wParam,
			     LPARAM lParam)
{
  Window *This;

  // Get our this pointer
  This = reinterpret_cast<Window *>(GetWindowLongPtr (hwnd, GWLP_USERDATA));

  return This->WindowProc (uMsg, wParam, lParam);
}

bool
Window::Create (Window * parent, DWORD Style)
{
  // First register the window class, if we haven't already
  if (registerWindowClass () == false)
    {
      // Registration failed
      return false;
    }

  // Save our parent, we'll probably need it eventually.
  Parent = parent;

  // Create the window instance
  WindowHandle = CreateWindowEx (
                   // Extended Style
                   0,
                   "MainWindowClass",	//MAKEINTATOM(WindowClassAtom),     // window class atom (name)
			       "Hello",	// no title-bar string yet
			       // Style bits
			       Style,
			       // Default positions and size
			       CW_USEDEFAULT,
			       CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,
			       // Parent Window
			       parent ==
			       NULL ? (HWND) NULL : parent->GetHWND (),
			       // use class menu
			       (HMENU) NULL,
			       // The application instance
			       GetInstance (),
			       // The this ptr, which we'll use to set up the WindowProc reflection.
			       (LPVOID) this);

  if (WindowHandle == NULL)
    {
      // Failed
      return false;
    }

  return true;
}

bool
Window::registerWindowClass ()
{
  if (WindowClassAtom == 0)
    {
      // We're not registered yet
      WNDCLASSEX wc;
      memset(&wc, 0, sizeof wc);
      wc.cbSize = sizeof wc;
      // Some sensible style defaults
      wc.style = CS_DBLCLKS | CS_HREDRAW | CS_VREDRAW;
      // Our default window procedure.  This replaces itself
      // on the first call with the simpler Window::WindowProcReflector().
      wc.lpfnWndProc = Window::FirstWindowProcReflector;
      // No class bytes
      wc.cbClsExtra = 0;
      // One pointer to REFLECTION_INFO in the extra window instance bytes
      wc.cbWndExtra = 4;
      // The app instance
      wc.hInstance = GetInstance ();
      // Use a bunch of system defaults for the GUI elements
      wc.hIcon = NULL;
      wc.hIconSm = NULL;
      wc.hCursor = NULL;
      wc.hbrBackground = (HBRUSH) (COLOR_BACKGROUND + 1);
      // No menu
      wc.lpszMenuName = NULL;
      // We'll get a little crazy here with the class name
      wc.lpszClassName = "MainWindowClass";

      // All set, try to register
      WindowClassAtom = RegisterClassEx (&wc);

      if (WindowClassAtom == 0)
	{
	  // Failed
	  return false;
	}
    }

  // We're registered, or already were before the call,
  // return success in either case.
  return true;
}

void
Window::Show (int State)
{
  ::ShowWindow (WindowHandle, State);
}

RECT
Window::GetWindowRect() const
{
  RECT retval;
  ::GetWindowRect(WindowHandle, &retval);
  return retval;
}

RECT
Window::GetClientRect() const
{
  RECT retval;
  ::GetClientRect(WindowHandle, &retval);
  return retval;
}

bool
Window::MoveWindow(long x, long y, long w, long h, bool Repaint)
{
  return ::MoveWindow (WindowHandle, x, y, w, h, Repaint) != 0;
}

bool
Window::MoveWindow(const RECTWrapper &r, bool Repaint)
{
  return ::MoveWindow (WindowHandle, r.left, r.top, r.width(), r.height(), Repaint) != 0;
}

void
Window::CenterWindow ()
{
  RECT WindowRect, ParentRect;
  int WindowWidth, WindowHeight;
  POINT p;

  // Get the window rectangle
  WindowRect = GetWindowRect ();

  if (GetParent () == NULL)
    {
      // Center on desktop window
      ::GetWindowRect (GetDesktopWindow (), &ParentRect);
    }
  else
    {
      // Center on client area of parent
      ::GetClientRect (GetParent ()->GetHWND (), &ParentRect);
    }

  WindowWidth = WindowRect.right - WindowRect.left;
  WindowHeight = WindowRect.bottom - WindowRect.top;

  // Find center of area we're centering on
  p.x = (ParentRect.right - ParentRect.left) / 2;
  p.y = (ParentRect.bottom - ParentRect.top) / 2;

  // Convert that to screen coords
  if (GetParent () == NULL)
    {
      ClientToScreen (GetDesktopWindow (), &p);
    }
  else
    {
      ClientToScreen (GetParent ()->GetHWND (), &p);
    }

  // Calculate new top left corner for window
  p.x -= WindowWidth / 2;
  p.y -= WindowHeight / 2;

  // And finally move the window
  MoveWindow (p.x, p.y, WindowWidth, WindowHeight);
}

LRESULT
Window::WindowProc (UINT uMsg, WPARAM wParam, LPARAM lParam)
{
  return DefWindowProc (WindowHandle, uMsg, wParam, lParam);
}

bool
Window::MessageLoop ()
{
  MSG
    msg;

  while (GetMessage (&msg, NULL, 0, 0) != 0
	 && GetMessage (&msg, (HWND) NULL, 0, 0) != -1)
    {
      if (!IsWindow (WindowHandle) || !IsDialogMessage (WindowHandle, &msg))
        {
          TranslateMessage (&msg);
          DispatchMessage (&msg);
        }
    }

  return true;
}

void
Window::PostMessageNow (UINT uMsg, WPARAM wParam, LPARAM lParam)
{
  ::PostMessage (GetHWND (), uMsg, wParam, lParam);
}

UINT
Window::IsButtonChecked (int nIDButton) const
{
  return ::IsDlgButtonChecked (GetHWND (), nIDButton);
}

bool
Window::SetDlgItemFont (int id, const TCHAR * fontname, int Pointsize,
			  int Weight, bool Italic, bool Underline,
			  bool Strikeout)
{
  HWND ctrl;

  ctrl = GetDlgItem (id);
  if (ctrl == NULL)
    {
      // Couldn't get that ID
      return false;
    }

  // We need the DC for the point size calculation.
  HDC hdc = GetDC (ctrl);

  // Create the font.  We have to keep it around until the dialog item
  // goes away - basically until we're destroyed.
  HFONT hfnt;
  hfnt =
    CreateFont (-MulDiv (Pointsize, GetDeviceCaps (hdc, LOGPIXELSY), 72), 0,
		0, 0, Weight, Italic ? TRUE : FALSE,
		Underline ? TRUE : FALSE, Strikeout ? TRUE : FALSE,
		ANSI_CHARSET, OUT_TT_PRECIS, CLIP_DEFAULT_PRECIS,
		PROOF_QUALITY, DEFAULT_PITCH | FF_DONTCARE, fontname);
  if (hfnt == NULL)
    {
      // Font creation failed
      return false;
    }

  // Set the new font, and redraw any text which was already in the item.
  SendMessage (ctrl, WM_SETFONT, (WPARAM) hfnt, TRUE);

  // Store the handle so that we can DeleteObject() it in dtor
  Fonts.push_back (hfnt);

  return true;
}

void
Window::SetWindowText (const std::string& s)
{
  ::SetWindowText (WindowHandle, s.c_str ());
}

RECT
Window::ScreenToClient(const RECT &r) const
{
  POINT tl;
  POINT br;

  tl.y = r.top;
  tl.x = r.left;
  ::ScreenToClient(GetHWND(), &tl);
  br.y = r.bottom;
  br.x = r.right;
  ::ScreenToClient(GetHWND(), &br);

  RECT ret;

  ret.top = tl.y;
  ret.left = tl.x;
  ret.bottom = br.y;
  ret.right = br.x;

  return ret;
}

void
Window::ActivateTooltips ()
// initialization of the tooltip capability
{
  if (TooltipHandle != NULL)
    return;     // already initialized

  // create a window for the tool tips - will be invisible most of the time
  if ((TooltipHandle = CreateWindowEx (0, (LPCTSTR) TOOLTIPS_CLASS, NULL,
        WS_POPUP | TTS_NOPREFIX | TTS_ALWAYSTIP, CW_USEDEFAULT,
        CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, GetHWND (),
        (HMENU) 0, GetInstance (), (LPVOID) 0)) == (HWND) NULL)
    {
      log (LOG_PLAIN) << "Warning: call to CreateWindowEx failed when "
              "initializing tooltips.  Error = %8.8x" << GetLastError ()
              << endLog;
      return;
    }

  // must be topmost so that tooltips will display on top
  SetWindowPos (TooltipHandle, HWND_TOPMOST, 0, 0, 0, 0,
              SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);

  // some of our tooltips are lengthy, and will disappear before they can be
  // read with the default windows delay, so we set a long (30s) delay here.
  SendMessage (TooltipHandle, TTM_SETDELAYTIME, TTDT_AUTOPOP,
               (LPARAM) MAKELONG (30000, 0));
}

void
Window::SetTooltipState (bool b)
// enable/disable tooltips
{
  SendMessage (TooltipHandle, (UINT)TTM_ACTIVATE, (WPARAM)(BOOL)b, 0);
}

void
Window::AddTooltip (HWND target, HWND win, const char *text)
// adds a tooltip to element 'target' in window 'win'
// note: text is limited to 80 chars (grumble)
{
  if (!TooltipHandle)
    ActivateTooltips ();

  TOOLINFO ti;
  memset (&ti, 0, sizeof ti);
  ti.cbSize = sizeof ti;

  ti.uFlags = TTF_IDISHWND    // add tool based on handle not ID
            | TTF_SUBCLASS;   // tool is to subclass the window in order
                              // to automatically get mouse events
  ti.hwnd = win;
  ti.uId = reinterpret_cast<UINT_PTR>(target);
  ti.lpszText = (LPTSTR)text; // pointer to text or string resource

  SendMessage (TooltipHandle, (UINT)TTM_ADDTOOL, 0,
               (LPARAM)(LPTOOLINFO)&ti);
}

void
Window::AddTooltip (int id, const char *text)
// adds a tooltip to a control identified by its ID
{
  HWND target, parent;

  if ((target = GetDlgItem (id)) != NULL &&
      (parent = ::GetParent (target)) != NULL)
    AddTooltip (target, parent, text);
}

void
Window::AddTooltip (int id, int string_resource)
// adds a tooltip that's represented by a string resource
// this also allows for tooltips greater than 80 characters
// we do this by setting the lpszText to LPSTR_TEXTCALLBACK
// and then responding to the TTN_GETDISPINFO notification
// in order to do this we store a list of (control ID, string ID) pairs
{
  AddTooltip (id, (const char *)LPSTR_TEXTCALLBACK);
  TooltipStrings[id] = string_resource;
}

BOOL
Window::TooltipNotificationHandler (LPARAM lParam)
// this is the handler for TTN_GETDISPINFO notifications
{
  NMTTDISPINFO *dispinfo = (NMTTDISPINFO *)lParam;
  int ctrlID;
  std::map<int, int>::iterator findID;

  if ((dispinfo->uFlags & TTF_IDISHWND) &&
      ((ctrlID = GetDlgCtrlID ((HWND)dispinfo->hdr.idFrom)) != 0) &&
      ((findID = TooltipStrings.find (ctrlID)) != TooltipStrings.end ())) {

    // enable multiple lines
    SendMessage(dispinfo->hdr.hwndFrom, TTM_SETMAXTIPWIDTH, 0, 450);

    dispinfo->lpszText = strdup( loadRString( findID->second ).c_str() );

    // set this flag so that the control will not ask for this again
    dispinfo->uFlags |= TTF_DI_SETITEM;
    dispinfo->hinst = NULL;
    return TRUE;
  }

  return FALSE;
}

void
Window::SetBusy (void)
{
  // The docs suggest that you can call SetCursor, and it won't do
  // anything if you've chosen the same cursor as is already set.
  // However it looked to me as if it was resetting the animation
  // frame every time when I tried it, hence this routine to make
  // sure we only call it once on the way into and once on the way
  // out of busy mode.
  if (BusyCount++ == 0)
    {
      if (BusyCursor == NULL)
	BusyCursor = LoadCursor (NULL, IDC_WAIT);
      OldCursor = SetCursor (BusyCursor);
    }
}

void
Window::ClearBusy (void)
{
  if (BusyCount && (--BusyCount == 0))
    {
      SetCursor (OldCursor);
    }
}

std::string
Window::loadRString( int id )
{
  TCHAR buffer[2048];
  int len = LoadString( GetInstance (), id, buffer, sizeof buffer );
  if( len>0 )
    return std::string( buffer, len );
  else
    return std::string();
}

std::string
Window::sprintf( const char *fmt, ...)
{
  std::string str;
  va_list args;
  va_start( args, fmt );
  int len = vsnprintf( 0, 0, fmt, args );
  str.resize( len+1 );
  vsnprintf( (char *) str.data(), len+1, fmt, args );
  return str;
}
