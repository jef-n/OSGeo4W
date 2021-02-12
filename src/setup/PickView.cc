/*
 * Copyright (c) 2002 Robert Collins.
 *
 *     This program is free software; you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation; either version 2 of the License, or
 *     (at your option) any later version.
 *
 *     A copy of the GNU General Public License can be found at
 *     http://www.gnu.org/
 *
 * Written by Robert Collins <robertc@hotmail.com>
 *
 */

#include "PickView.h"
#include <algorithm>
#include <limits.h>
#include <commctrl.h>
#include <shlwapi.h>
#include "PickPackageLine.h"
#include "PickCategoryLine.h"
#include "package_db.h"
#include "package_version.h"
#include "dialog.h"
#include "resource.h"
/* For 'source' */
#include "state.h"
#include "LogSingleton.h"
#include "msg.h"

using namespace std;

static PickView::Header pkg_headers[] = {
  {IDS_LIST_CURRENT, 0, 0, true},
  {IDS_LIST_NEW, 0, 0, true},
  {IDS_LIST_BIN, 0, 0, false},
  {IDS_LIST_SRC, 0, 0, false},
  {IDS_LIST_CATEGORIES, 0, 0, true},
  {IDS_LIST_SIZE, 0, 0, true},
  {IDS_LIST_PACKAGE, 0, 0, true},
  {0, 0, 0, false}
};

static PickView::Header cat_headers[] = {
  {IDS_LIST_CATEGORY, 0, 0, true},
  {IDS_LIST_CURRENT, 0, 0, true},
  {IDS_LIST_NEW, 0, 0, true},
  {IDS_LIST_BIN, 0, 0, false},
  {IDS_LIST_SRC, 0, 0, false},
  {IDS_LIST_SIZE, 0, 0, true},
  {IDS_LIST_PACKAGE, 0, 0, true},
  {0, 0, 0, false}
};

// PickView:: views
const PickView::views PickView::views::Unknown (0);
const PickView::views PickView::views::PackageFull (1);
const PickView::views PickView::views::Package (2);
const PickView::views PickView::views::PackageKeeps (3);
const PickView::views PickView::views::PackageSkips = PickView::views (4);
const PickView::views PickView::views::Category (5);

ATOM PickView::WindowClassAtom = 0;

// DoInsertItem - inserts an item into a header control.
// Returns the index of the new item.
// hwndHeader - handle to the header control.
// iInsertAfter - index of the previous item.
// nWidth - width of the new item.
// lpsz - address of the item string.
static LRESULT
DoInsertItem (HWND hwndHeader, int iInsertAfter, int nWidth, LPSTR lpsz)
{
  HDITEM hdi;
  LRESULT index;

  hdi.mask = HDI_TEXT | HDI_FORMAT | HDI_WIDTH;
  hdi.pszText = lpsz;
  hdi.cxy = nWidth;
  hdi.cchTextMax = lstrlen (hdi.pszText);
  hdi.fmt = HDF_LEFT | HDF_STRING;

  index = SendMessage (hwndHeader, HDM_INSERTITEM,
                       (WPARAM) iInsertAfter, (LPARAM) & hdi);

  return index;
}

int
PickView::set_header_column_order (views vm)
{
  if (vm == views::Unknown)
    return -1;

  if (vm == views::PackageFull ||
      vm == views::Package ||
      vm == views::PackageKeeps ||
      vm == views::PackageSkips)
    {
      headers = pkg_headers;
      current_col = 0;
      new_col = 1;
      bintick_col = new_col + 1;
      srctick_col = bintick_col + 1;
      cat_col = srctick_col + 1;
      size_col = cat_col + 1;
      pkg_col = size_col + 1;
      last_col = pkg_col;
    }
  else if (vm == views::Category)
    {
      headers = cat_headers;
      cat_col = 0;
      current_col = 1;
      new_col = current_col + 1;
      bintick_col = new_col + 1;
      srctick_col = bintick_col + 1;
      size_col = srctick_col + 1;
      pkg_col = size_col + 1;
      last_col = pkg_col;
    }
  else
    return -1;
  return last_col;
}

void
PickView::set_headers ()
{
  if (set_header_column_order (view_mode) == -1)
    return;
  while (LRESULT n = SendMessage (listheader, HDM_GETITEMCOUNT, 0, 0))
    {
      SendMessage (listheader, HDM_DELETEITEM, n - 1, 0);
    }
  int i;
  for (i = 0; i <= last_col; i++)
    DoInsertItem (listheader, i, headers[i].width, (char *) loadRString( headers[i].resid ).c_str());
}

void
PickView::note_width (PickView::Header *hdrs, HDC dc,
                      const std::string& string, int addend, int column)
{
  SIZE s = { 0, 0 };

  if (string.size())
    GetTextExtentPoint32 (dc, string.c_str(), (int) string.size(), &s);
  if (hdrs[column].width < s.cx + addend)
    hdrs[column].width = s.cx + addend;
}

void
PickView::cycleViewMode ()
{
  setViewMode (++view_mode);
}

void
PickView::setViewMode (views mode)
{
  view_mode = mode;
  set_headers ();
  packagedb db;

  contents.empty ();
  if (view_mode == PickView::views::Category)
    {
      contents.ShowLabel (true);
      /* start collapsed. TODO: make this a chooser flag */
      for (packagedb::categoriesType::iterator n =
            packagedb::categories.begin(); n != packagedb::categories.end();
            ++n)
        insert_category (&*n, (*n).first.c_str()[0] == '.'
				? CATEGORY_EXPANDED : CATEGORY_COLLAPSED);
    }
  else
    {
      contents.ShowLabel (false);
      // iterate through every package
      for (packagedb::packagecollection::iterator i = db.packages.begin ();
          i != db.packages.end (); ++i)
        {
          packagemeta & pkg = *(i->second);

          if ( // "Full" : everything
              (view_mode == PickView::views::PackageFull)

              // "Pending" : packages that are being added/removed/upgraded
              || (view_mode == PickView::views::Package &&
                ((!pkg.desired && pkg.installed) ||         // uninstall
                 (pkg.desired &&
                  (pkg.desired.picked () ||               // install bin
                   pkg.desired.sourcePackage ().picked ())))) // src

              // "Up to date" : installed packages that will not be changed
              || (view_mode == PickView::views::PackageKeeps &&
                (pkg.installed && pkg.desired && !pkg.desired.picked ()
                 && !pkg.desired.sourcePackage ().picked ()))

              // "Not installed"
              || (view_mode == PickView::views::PackageSkips &&
                (!pkg.desired && !pkg.installed)))
            {
              // Filter by package name
              if (packageFilterString.empty ()
                  || StrStrI (pkg.name.c_str (), packageFilterString.c_str ()))
                insert_pkg (pkg);
            }
        }
    }

  RECT r = GetClientRect ();
  SCROLLINFO si;
  memset (&si, 0, sizeof si);
  si.cbSize = sizeof si;
  si.fMask = SIF_ALL | SIF_DISABLENOSCROLL;
  si.nMin = 0;
  si.nMax = headers[last_col].x + headers[last_col].width;    // + HMARGIN;
  si.nPage = r.right;
  SetScrollInfo (GetHWND(), SB_HORZ, &si, TRUE);

  si.nMax = contents.itemcount () * row_height;
  si.nPage = r.bottom - header_height;
  SetScrollInfo (GetHWND(), SB_VERT, &si, TRUE);

  scroll_ulc_x = scroll_ulc_y = 0;

  InvalidateRect (GetHWND(), &r, TRUE);
}

std::string
PickView::mode_caption ()
{
  return view_mode.caption ();
}

std::string
PickView::views::caption()
{
  int ids[] = {
                IDS_CAPTION_FULL,
                IDS_CAPTION_PENDING,
                IDS_CAPTION_UPTODATE,
                IDS_CAPTION_NOTINSTALLED,
                IDS_CAPTION_CATEGORY
              };

  int v = _value - 1;

  if( v < 0 || v >= (int) ( sizeof ids / sizeof *ids ) )
    return std::string();
  else
    return Window::loadRString( ids[v] );
}

/* meant to be called on packagemeta::categories */
bool
isObsolete (set <std::string, casecompare_lt_op> &categories)
{
  set <std::string, casecompare_lt_op>::const_iterator i;

  for (i = categories.begin (); i != categories.end (); ++i)
    if (isObsolete (*i))
      return true;
  return false;
}

bool
isObsolete (const std::string& catname)
{
  if (casecompare(catname, "ZZZRemovedPackages") == 0
        || casecompare(catname, "_", 1) == 0)
    return true;
  return false;
}

/* Sets the mode for showing/hiding obsolete junk packages.  */
void
PickView::setObsolete (bool doit)
{
  showObsolete = doit;
  refresh ();
}


void
PickView::insert_pkg (packagemeta & pkg)
{
  if (!showObsolete && isObsolete (pkg.categories))
    return;

  if (view_mode != views::Category)
    {
      PickLine & line = *new PickPackageLine (*this, pkg);
      contents.insert (line);
    }
  else
    {
      for (set <std::string, casecompare_lt_op>::const_iterator x
	   = pkg.categories.begin (); x != pkg.categories.end (); ++x)
        {
	  // Special case - yuck
	  if (casecompare(*x, "All") == 0)
	    continue;

	  packagedb db;
	  PickCategoryLine & catline =
	    *new PickCategoryLine (*this, *db.categories.find (*x), 1);
	  PickLine & line = *new PickPackageLine(*this, pkg);
	  catline.insert (line);
	  contents.insert (catline);
        }
    }
}

void
PickView::insert_category (Category *cat, bool collapsed)
{
  // Urk, special case
  if (casecompare(cat->first, "All") == 0 ||
      (!showObsolete && isObsolete (cat->first)))
    return;
  PickCategoryLine & catline = *new PickCategoryLine (*this, *cat, 1, collapsed);
  int packageCount = 0;
  for (vector <packagemeta *>::iterator i = cat->second.begin ();
       i != cat->second.end () ; ++i)
    {
      if (packageFilterString.empty ()
          || (*i
	      && StrStrI ((*i)->name.c_str (), packageFilterString.c_str ())))
	{
	  PickLine & line = *new PickPackageLine (*this, **i);
	  catline.insert (line);
	  packageCount++;
	}
    }

  if (packageFilterString.empty () || packageCount)
    contents.insert (catline);
  else
    delete &catline;
}

PickView::views&
PickView::views::operator++ ()
{
  ++_value;
  if (_value > Category._value)
    _value = 1;
  return *this;
}

int
PickView::click (int row, int x)
{
  return contents.click (0, row, x);
}


void
PickView::scroll (HWND hwnd, int which, int *var, int code, int howmany = 1)
{
  SCROLLINFO si;
  memset(&si, 0, sizeof si);
  si.cbSize = sizeof si;
  si.fMask = SIF_ALL | SIF_DISABLENOSCROLL;
  GetScrollInfo (hwnd, which, &si);

  switch (code)
    {
    case SB_THUMBTRACK:
      si.nPos = si.nTrackPos;
      break;
    case SB_THUMBPOSITION:
      break;
    case SB_BOTTOM:
      si.nPos = si.nMax;
      break;
    case SB_TOP:
      si.nPos = 0;
      break;
    case SB_LINEDOWN:
      si.nPos += (row_height * howmany);
      break;
    case SB_LINEUP:
      si.nPos -= (row_height * howmany);
      break;
    case SB_PAGEDOWN:
      si.nPos += si.nPage * 9 / 10;
      break;
    case SB_PAGEUP:
      si.nPos -= si.nPage * 9 / 10;
      break;
    }

  if ((int) si.nPos < 0)
    si.nPos = 0;
  if (si.nPos + si.nPage > (unsigned int) si.nMax)
    si.nPos = si.nMax - si.nPage;

  si.fMask = SIF_POS;
  SetScrollInfo (hwnd, which, &si, TRUE);

  int ox = scroll_ulc_x;
  int oy = scroll_ulc_y;
  *var = si.nPos;

  RECT cr, sr;
  ::GetClientRect (hwnd, &cr);
  sr = cr;
  sr.top += header_height;
  UpdateWindow (hwnd);
  ScrollWindow (hwnd, ox - scroll_ulc_x, oy - scroll_ulc_y, &sr, &sr);
  /*
     sr.bottom = sr.top;
     sr.top = cr.top;
     ScrollWindow (hwnd, ox - scroll_ulc_x, 0, &sr, &sr);
   */
  if (ox - scroll_ulc_x)
    {
      ::GetClientRect (listheader, &cr);
      sr = cr;
//  UpdateWindow (htmp);
      ::MoveWindow (listheader, -scroll_ulc_x, 0,
                  headers[last_col].x +
                  headers[last_col].width, header_height, TRUE);
    }
  UpdateWindow (hwnd);
}

/* this means to make the 'category' column wide enough to fit the first 'n'
   categories for each package.  */
#define NUM_CATEGORY_COL_WIDTH 2

void
PickView::init_headers (HDC dc)
{
  int i;

  for (i = 0; headers[i].resid; i++)
    {
      headers[i].width = 0;
      headers[i].x = 0;
    }

  // accomodate widths of the 'bin' and 'src' checkbox columns
  // FIXME: What's up with the "0"? It's probably a mistake, and should be
  // "". It used to be written as 0, and was subject to a bizarre implicit
  // conversion by the unwise String(int) constructor.
  note_width (headers, dc, "0", HMARGIN + 11, bintick_col);
  note_width (headers, dc, "0", HMARGIN + 11, srctick_col);

  // accomodate the width of each category name
  packagedb db;
  for (packagedb::categoriesType::iterator n = packagedb::categories.begin();
       n != packagedb::categories.end(); ++n)
    {
      if (!showObsolete && isObsolete (n->first))
        continue;
      note_width (headers, dc, n->first, HMARGIN, cat_col);
    }

  /* For each package, accomodate the width of the installed version in the
     current_col, the widths of all other versions in the new_col, and the
     width of the sdesc for the pkg_col.  Also, if this is not a Category
     view, adjust the 'category' column so that the first NUM_CATEGORY_COL_WIDTH
     categories from each package fits.  */
  for (packagedb::packagecollection::iterator n = db.packages.begin ();
       n != db.packages.end (); ++n)
    {
      packagemeta & pkg = *(n->second);
      if (!showObsolete && isObsolete (pkg.categories))
        continue;
      if (pkg.installed)
        note_width (headers, dc, pkg.installed.Canonical_version (),
                    HMARGIN, current_col);
      for (set<packageversion>::iterator i = pkg.versions.begin ();
	   i != pkg.versions.end (); ++i)
	{
          if (*i != pkg.installed)
            note_width (headers, dc, i->Canonical_version (),
                        HMARGIN + SPIN_WIDTH, new_col);
	  std::string z = format_1000s(packageversion(*i).source ()->size);
	  note_width (headers, dc, z, HMARGIN, size_col);
	  z = format_1000s(packageversion(i->sourcePackage ()).source ()->size);
	  note_width (headers, dc, z, HMARGIN, size_col);
	}
      std::string s = pkg.name;
      if (pkg.SDesc ().size())
	s += std::string (": ") + std::string(pkg.SDesc ());
      note_width (headers, dc, s, HMARGIN, pkg_col);

      if (view_mode != PickView::views::Category && pkg.categories.size () > 2)
        {
          std::string compound_cat("");
          std::set<std::string, casecompare_lt_op>::const_iterator cat;
          size_t cnt;

          for (cnt = 0, cat = pkg.categories.begin ();
               cnt < NUM_CATEGORY_COL_WIDTH && cat != pkg.categories.end ();
               ++cat)
            {
              if (casecompare(*cat, "All") == 0)
                continue;
              if (compound_cat.size ())
                compound_cat += ", ";
              compound_cat += *cat;
              cnt++;
            }
          note_width (headers, dc, compound_cat, HMARGIN, cat_col);
        }
    }

  // ensure that the new_col is wide enough for all the labels
  int captions[] = {
                     IDS_UNINSTALL,
                     IDS_SKIP,
                     IDS_REINSTALL,
                     IDS_RETRIEVE,
                     IDS_SOURCE,
                     IDS_KEEP,
                     0,
                   };
  for (int i = 0; captions[i]; i++)
    note_width (headers, dc, loadRString( captions[i] ).c_str(), HMARGIN + SPIN_WIDTH, new_col);

  // finally, compute the actual x values based on widths
  headers[0].x = 0;
  for (i = 1; i <= last_col; i++)
    headers[i].x = headers[i - 1].x + headers[i - 1].width;
  // and allow for resizing to ensure the last column reaches
  // all the way to the end of the chooser box.
  headers[last_col].width += total_delta_x;
}


PickView::PickView (Category &cat)
  : deftrust (TRUST_UNKNOWN)
  , contents (*this, cat, 0, false, true)
  , showObsolete (false)
  , packageFilterString ()
  , hasWindowRect (false)
  , total_delta_x (0)
{
}

HANDLE
PickView::loadImage( int id )
{
  HANDLE handle = LoadImage ( GetModuleHandle ( NULL ), MAKEINTRESOURCE (id), IMAGE_BITMAP, 0, 0, 0);

  if( handle )
    return handle;

  char *buf;
  if (FormatMessage (FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER, 0, GetLastError(), LANG_NEUTRAL, (LPSTR)&buf, 0, 0) != 0)
    {
      log (LOG_BABBLE) << "could not load " << id << ": " << buf << endLog;
      LocalFree( buf );
    }
  else
    {
      log (LOG_BABBLE) << "could not load " << id << ": unknown error" << buf << endLog;
    }

  return 0;
}

void
PickView::init(views _mode)
{
  HDC dc = GetDC (GetHWND());
  sysfont = GetStockObject (DEFAULT_GUI_FONT);
  SelectObject (dc, sysfont);
  GetTextMetrics (dc, &tm);

  bitmap_dc = CreateCompatibleDC (dc);
  bm_spin = loadImage (IDB_SPIN);
  bm_checkyes = loadImage (IDB_CHECK_YES);
  bm_checkno = loadImage (IDB_CHECK_NO);
  bm_checkna = loadImage (IDB_CHECK_NA);
  bm_treeplus = loadImage (IDB_TREE_PLUS);
  bm_treeminus = loadImage (IDB_TREE_MINUS);

  icon_dc = CreateCompatibleDC (dc);
  bm_icon = CreateCompatibleBitmap (dc, 11, 11);
  SelectObject (icon_dc, bm_icon);
  rect_icon = CreateRectRgn (0, 0, 11, 11);

  row_height = (tm.tmHeight + tm.tmExternalLeading + ROW_MARGIN);
  int irh = tm.tmExternalLeading + tm.tmDescent + 11 + ROW_MARGIN;
  if (row_height < irh)
    row_height = irh;

  HDLAYOUT hdl;
  WINDOWPOS wp;

  // Ensure that the common control DLL is loaded, and then create
  // the header control.
  INITCOMMONCONTROLSEX controlinfo =
    { sizeof (INITCOMMONCONTROLSEX), ICC_LISTVIEW_CLASSES };
  InitCommonControlsEx (&controlinfo);

  if ((listheader = CreateWindowEx (0, WC_HEADER, (LPCTSTR) NULL,
                                    WS_CHILD | WS_BORDER | CCS_NORESIZE |
                                    // | HDS_BUTTONS
                                    HDS_HORZ, 0, 0, 0, 0, GetHWND(),
                                    (HMENU) IDC_CHOOSE_LISTHEADER, hinstance,
                                    (LPVOID) NULL)) == NULL)
    // FIXME: throw an exception
    exit (10);

  // Retrieve the bounding rectangle of the parent window's
  // client area, and then request size and position values
  // from the header control.
  RECT rcParent = GetClientRect ();

  hdl.prc = &rcParent;
  hdl.pwpos = &wp;
  if (!SendMessage (listheader, HDM_LAYOUT, 0, (LPARAM) & hdl))
    // FIXME: throw an exception
    exit (11);

  // Set the font of the listheader, but don't redraw, because its not shown
  // yet.This message does not return a value, so we are not checking it as we
  // do above.
  SendMessage (listheader, WM_SETFONT, (WPARAM) sysfont, FALSE);

  // Set the size, position, and visibility of the header control.
  SetWindowPos (listheader, wp.hwndInsertAfter, wp.x, wp.y,
                wp.cx, wp.cy, wp.flags | SWP_SHOWWINDOW);

  header_height = wp.cy;
  ReleaseDC (GetHWND (), dc);

  view_mode = _mode;
  refresh ();
}

PickView::~PickView()
{
  DeleteDC (bitmap_dc);
  DeleteObject (bm_spin);
  DeleteObject (bm_checkyes);
  DeleteObject (bm_checkno);
  DeleteObject (bm_checkna);
  DeleteObject (bm_treeplus);
  DeleteObject (bm_treeminus);
  DeleteObject (rect_icon);
  DeleteObject (bm_icon);
  DeleteDC (icon_dc);
}

bool PickView::registerWindowClass ()
{
  if (WindowClassAtom != 0)
    return true;

  // We're not registered yet
  WNDCLASSEX wc;
  memset(&wc, 0, sizeof wc);
  wc.cbSize = sizeof wc;
  // Some sensible style defaults
  wc.style = CS_HREDRAW | CS_VREDRAW;
  // Our default window procedure.  This replaces itself
  // on the first call with the simpler Window::WindowProcReflector().
  wc.lpfnWndProc = Window::FirstWindowProcReflector;
  // No class bytes
  wc.cbClsExtra = 0;
  // One pointer to REFLECTION_INFO in the extra window instance bytes
  wc.cbWndExtra = 4;
  // The app instance
  wc.hInstance = hinstance; //GetInstance ();
  // Use a bunch of system defaults for the GUI elements
  wc.hIcon = LoadIcon (0, IDI_APPLICATION);
  wc.hIconSm = NULL;
  wc.hCursor = LoadCursor (0, IDC_ARROW);
  wc.hbrBackground = NULL;
  // No menu
  wc.lpszMenuName = NULL;
  // We'll get a little crazy here with the class name
  wc.lpszClassName = "listview";

  // All set, try to register
  WindowClassAtom = RegisterClassEx (&wc);
  if (WindowClassAtom == 0)
    log (LOG_BABBLE) << "Failed to register listview " << GetLastError () << endLog;
  return WindowClassAtom != 0;
}

LRESULT CALLBACK
PickView::list_vscroll (HWND hwnd, HWND hctl, UINT code, int pos)
{
  scroll (hwnd, SB_VERT, &scroll_ulc_y, code);
  return 0;
}

LRESULT CALLBACK
PickView::list_hscroll (HWND hwnd, HWND hctl, UINT code, int pos)
{
  scroll (hwnd, SB_HORZ, &scroll_ulc_x, code);
  return 0;
}

void
PickView::set_vscroll_info (const RECT &r)
{
  SCROLLINFO si;
  memset (&si, 0, sizeof si);
  si.cbSize = sizeof si;
  si.fMask = SIF_ALL | SIF_DISABLENOSCROLL;    /* SIF_RANGE was giving strange behaviour */
  si.nMin = 0;

  si.nMax = contents.itemcount () * row_height;
  si.nPage = r.bottom - header_height;

  /* if we are under the minimum display count ,
   * set the offset to 0
   */
  if ((unsigned int) si.nMax <= si.nPage)
    scroll_ulc_y = 0;
  si.nPos = scroll_ulc_y;

  SetScrollInfo (GetHWND(), SB_VERT, &si, TRUE);
}

LRESULT CALLBACK
PickView::list_click (HWND hwnd, BOOL dblclk, int x, int y, UINT hitCode)
{
  int row;

  if (contents.itemcount () == 0)
    return 0;

  if (y < header_height)
    return 0;
  x += scroll_ulc_x;
  y += scroll_ulc_y - header_height;

  row = (y + ROW_MARGIN / 2) / row_height;

  if (row < 0 || row >= contents.itemcount ())
    return 0;

  click (row, x);

  // XXX we need a method to query the database to see if more
  // than just one package has changed! Until then...
#if 0
  if (refresh)
    {
#endif
      RECT r = GetClientRect ();
      set_vscroll_info (r);
      InvalidateRect (GetHWND(), &r, TRUE);
#if 0
    }
  else
    {
      RECT rect;
      rect.left =
        headers[new_col].x - scroll_ulc_x;
      rect.right =
        headers[src_col + 1].x - scroll_ulc_x;
      rect.top =
        header_height + row * row_height -
        scroll_ulc_y;
      rect.bottom = rect.top + row_height;
      InvalidateRect (hwnd, &rect, TRUE);
    }
#endif
  return 0;
}

/*
 * LRESULT CALLBACK
 * PickView::listview_proc (HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
 */
LRESULT
PickView::WindowProc (UINT message, WPARAM wParam, LPARAM lParam)
{
  int wheel_notches;
  UINT wheel_lines;

  switch (message)
    {
    case WM_HSCROLL:
      list_hscroll (GetHWND(), (HWND)lParam, LOWORD(wParam), HIWORD(wParam));
      return 0;
    case WM_VSCROLL:
      list_vscroll (GetHWND(), (HWND)lParam, LOWORD(wParam), HIWORD(wParam));
      return 0;
    case WM_MOUSEWHEEL:
      // this is how many 'notches' the wheel scrolled, forward/up = positive
      wheel_notches = GET_WHEEL_DELTA_WPARAM(wParam) / 120;

      // determine how many lines the user has configred for a mouse scroll
      SystemParametersInfo(SPI_GETWHEELSCROLLLINES, 0, &wheel_lines, 0);

      if (wheel_lines == 0)   // do no scrolling
        return 0;
      else if (wheel_lines == WHEEL_PAGESCROLL)
        scroll (GetHWND (), SB_VERT, &scroll_ulc_y, (wheel_notches > 0) ?
                SB_PAGEUP : SB_PAGEDOWN);
      else
        scroll (GetHWND (), SB_VERT, &scroll_ulc_y, (wheel_notches > 0) ?
                SB_LINEUP : SB_LINEDOWN, wheel_lines * abs (wheel_notches));
      return 0; // handled
    case WM_LBUTTONDOWN:
      list_click (GetHWND(), FALSE, LOWORD(lParam), HIWORD(lParam), (UINT) wParam);
      return 0;
    case WM_PAINT:
      paint (GetHWND());
      return 0;
    case WM_NOTIFY:
      {
        // pnmh = (LPNMHDR) lParam
        LPNMHEADER phdr = (LPNMHEADER) lParam;
        switch (phdr->hdr.code)
          {
          case HDN_ITEMCHANGED:
            if (phdr->hdr.hwndFrom == ListHeader ())
              {
                if (phdr->pitem && phdr->pitem->mask & HDI_WIDTH)
                  headers[phdr->iItem].width = phdr->pitem->cxy;

                for (int i = 1; i <= last_col; i++)
                  headers[i].x = headers[i - 1].x + headers[i - 1].width;

                RECT r = GetClientRect ();
                SCROLLINFO si;
                si.cbSize = sizeof si;
                si.fMask = SIF_ALL | SIF_DISABLENOSCROLL;
                GetScrollInfo (GetHWND(), SB_HORZ, &si);

                int oldMax = si.nMax;
                si.nMax = headers[last_col].x + headers[last_col].width;
                if (si.nTrackPos && oldMax > si.nMax)
                  si.nTrackPos += si.nMax - oldMax;

                si.nPage = r.right;
                SetScrollInfo (GetHWND(), SB_HORZ, &si, TRUE);
                InvalidateRect (GetHWND(), &r, TRUE);
                if (si.nTrackPos && oldMax > si.nMax)
                  scroll (GetHWND(), SB_HORZ, &scroll_ulc_x, SB_THUMBTRACK);
              }
            break;
          }
        }
      break;
    case WM_SIZE:
      {
        // Note: WM_SIZE msgs only appear when 'just' scrolling the window
        RECT windowRect = GetWindowRect ();
        if (hasWindowRect)
          {
            int dx;
            if ((dx = windowRect.right - windowRect.left -
                        lastWindowRect.width ()) != 0)
              {
                cat_headers[set_header_column_order (views::Category)].width += dx;
                pkg_headers[set_header_column_order (views::Package)].width += dx;
                set_header_column_order (view_mode);
                set_headers ();
                ::MoveWindow (listheader, -scroll_ulc_x, 0,
                            headers[last_col].x +
                            headers[last_col].width, header_height, TRUE);
                total_delta_x += dx;
              }
	    if (windowRect.bottom - windowRect.top - lastWindowRect.height ())
	      set_vscroll_info (GetClientRect ());
          }
        else
          hasWindowRect = true;

        lastWindowRect = windowRect;
        return 0;
      }
    }

  // default: can't handle this message
  return DefWindowProc (GetHWND(), message, wParam, lParam);
}

////
// Turn black into foreground color and white into background color by
//   1) Filling a square with ~(FG^BG)
//   2) Blitting the bitmap on it with NOTSRCERASE (white->black; black->FG^BG)
//   3) Blitting the result on BG with SRCINVERT (white->BG; black->FG)
void
PickView::DrawIcon (HDC hdc, int x, int y, HANDLE hIcon)
{
  SelectObject (bitmap_dc, hIcon);
  FillRgn (icon_dc, rect_icon, bg_fg_brush);
  BitBlt (icon_dc, 0, 0, 11, 11, bitmap_dc, 0, 0, NOTSRCERASE);
  BitBlt (hdc, x, y, 11, 11, icon_dc, 0, 0, SRCINVERT);
///////////// On WinNT-based systems, we could've done the below instead
///////////// See http://support.microsoft.com/default.aspx?scid=kb;en-us;79212
//      SelectObject (hdc, GetSysColorBrush (COLOR_WINDOWTEXT));
//      HBITMAP bm_icon = CreateBitmap (11, 11, 1, 1, NULL);
//      SelectObject (icon_dc, bm_icon);
//      BitBlt (icon_dc, 0, 0, 11, 11, bitmap_dc, 0, 0, SRCCOPY);
//      MaskBlt (hdc, x2, by, 11, 11, bitmap_dc, 0, 0, bm_icon, 0, 0, MAKEROP4 (SRCAND, PATCOPY));
//      DeleteObject (bm_icon);
}

void
PickView::paint (HWND hwnd)
{
  // we want to retrieve the update region before calling BeginPaint,
  // because after we do that the update region is validated and we can
  // no longer retrieve it
  HRGN hUpdRgn = CreateRectRgn (0, 0, 0, 0);

  if (GetUpdateRgn (hwnd, hUpdRgn, FALSE) == 0)
    {
      // error?
      return;
    }

  // tell the system that we're going to begin painting our window
  // it will prevent further WM_PAINT messages from arriving until we're
  // done, and if any part of our window was invalidated while we are
  // painting, it will retrigger us so that we can fix it
  PAINTSTRUCT ps;
  HDC hdc = BeginPaint (hwnd, &ps);

  SelectObject (hdc, sysfont);
  SetTextColor (hdc, GetSysColor (COLOR_WINDOWTEXT));
  SetBkColor (hdc, GetSysColor (COLOR_WINDOW));
  FillRgn (hdc, hUpdRgn, GetSysColorBrush(COLOR_WINDOW));

  COLORREF clr = ~GetSysColor (COLOR_WINDOW) ^ GetSysColor (COLOR_WINDOWTEXT);
  clr = RGB (GetRValue (clr), GetGValue (clr), GetBValue (clr)); // reconvert
  bg_fg_brush = CreateSolidBrush (clr);

  RECT cr;
  ::GetClientRect (hwnd, &cr);

  int x = cr.left - scroll_ulc_x;
  int y = cr.top - scroll_ulc_y + header_height;

  contents.paint (hdc, hUpdRgn, x, y, 0,
    (view_mode == PickView::views::Category) ? 0 : 1);

  if (contents.itemcount () == 0)
    {
      std::string buf = loadRString(
          source == IDC_SOURCE_DOWNLOAD
	  ? IDS_NOTHING_TO_DOWNLOAD
	  : IDS_NOTHING_TO_INSTALL_OR_UPGRADE
	);
      TextOut (hdc, x + HMARGIN, y, buf.c_str(), (int) buf.size() );
    }

  DeleteObject (hUpdRgn);
  DeleteObject (bg_fg_brush);
  EndPaint (hwnd, &ps);
}

bool
PickView::Create (Window * parent, DWORD Style, RECT *r)
{

  // First register the window class, if we haven't already
  if (!registerWindowClass ())
    {
      // Registration failed
      return false;
    }

  // Save our parent, we'll probably need it eventually.
  setParent(parent);

  // Create the window instance
  CreateWindowEx (// Extended Style
                  WS_EX_CLIENTEDGE,
                  // window class atom (name)
                  "listview",   //MAKEINTATOM(WindowClassAtom),
                  "listviewwindow", // no title-bar string yet
                  // Style bits
                  Style,
                  r ? r->left : CW_USEDEFAULT,
                  r ? r->top : CW_USEDEFAULT,
                  r ? r->right - r->left + 1 : CW_USEDEFAULT,
                  r ? r->bottom - r->top + 1 : CW_USEDEFAULT,
                  // Parent Window
                  parent == NULL ? (HWND)NULL : parent->GetHWND (),
                  // use class menu
                  (HMENU) MAKEINTRESOURCE (IDC_CHOOSE_LIST),
                  // The application instance
                  GetInstance (),
                  // The this ptr, which we'll use to set up
                  // the WindowProc reflection.
                  reinterpret_cast<void *>((Window *)this));
  if (GetHWND() == NULL)
    {
      log (LOG_BABBLE) << "Failed to create PickView " << GetLastError () << endLog;
      return false;
    }

  return true;
}

void
PickView::defaultTrust (trusts trust)
{
  this->deftrust = trust;

  packagedb db;
  db.defaultTrust(trust);

  // force the picker to redraw
  RECT r = GetClientRect ();
  InvalidateRect (this->GetHWND(), &r, TRUE);
}

/* This recalculates all column widths and resets the view */
void
PickView::refresh()
{
  HDC dc = GetDC (GetHWND ());

  // we must set the font of the DC here, otherwise the width calculations
  // will be off because the system will use the wrong font metrics
  sysfont = GetStockObject (DEFAULT_GUI_FONT);
  SelectObject (dc, sysfont);

  // init headers for the current mode
  set_headers ();
  init_headers (dc);

  // save the current mode
  views cur_view_mode = view_mode;

  // switch to the other type and do those headers
  view_mode = (view_mode == PickView::views::Category) ?
                    PickView::views::PackageFull : PickView::views::Category;
  set_headers ();
  init_headers (dc);
  ReleaseDC (GetHWND (), dc);

  view_mode = cur_view_mode;
  setViewMode (view_mode);
}
