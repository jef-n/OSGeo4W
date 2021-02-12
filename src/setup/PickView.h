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

#ifndef SETUP_PICKVIEW_H
#define SETUP_PICKVIEW_H

#include <string>
#include "win32.h"
#include "window.h"
#include "RECTWrapper.h"

#define HMARGIN         10
#define ROW_MARGIN      5
#define ICON_MARGIN     4
#define SPIN_WIDTH      11
#define CHECK_SIZE      11
#define TREE_INDENT     12

#define CATEGORY_EXPANDED  0
#define CATEGORY_COLLAPSED 1

class PickView;
#include "PickCategoryLine.h"
#include "package_meta.h"

class PickView : public Window
{
public:
  virtual bool Create (Window * Parent = NULL, DWORD Style = WS_OVERLAPPEDWINDOW | WS_VISIBLE | WS_CLIPCHILDREN, RECT * r = NULL);
  virtual bool registerWindowClass ();
  class views;
  class Header;
  int num_columns;
  void defaultTrust (trusts trust);
  void cycleViewMode ();
  void setViewMode (views mode);
  void DrawIcon (HDC hdc, int x, int y, HANDLE hIcon);
  void paint (HWND hwnd);
  LRESULT CALLBACK list_click (HWND hwnd, BOOL dblclk, int x, int y, UINT hitCode);
  LRESULT CALLBACK list_hscroll (HWND hwnd, HWND hctl, UINT code, int pos);
  LRESULT CALLBACK list_vscroll (HWND hwnd, HWND hctl, UINT code, int pos);
  void set_vscroll_info (const RECT &r);
  virtual LRESULT WindowProc (UINT uMsg, WPARAM wParam, LPARAM lParam);
  Header *headers;
  PickView (Category & cat);
  void init(views _mode);
  ~PickView();
  std::string mode_caption ();
  void setObsolete (bool doit);
  void insert_pkg (packagemeta &);
  void insert_category (Category *, bool);
  int click (int row, int x);
  void refresh();
  int current_col;
  int new_col;
  int bintick_col;
  int srctick_col;
  int cat_col;
  int size_col;
  int pkg_col;
  int last_col;
  int row_height;
  TEXTMETRIC tm;
  HDC bitmap_dc, icon_dc;
  HBITMAP bm_icon;
  HRGN rect_icon;
  HBRUSH bg_fg_brush;
  HANDLE bm_spin, bm_checkyes, bm_checkno, bm_checkna, bm_treeplus, bm_treeminus;
  trusts deftrust;
  HANDLE sysfont;
  int scroll_ulc_x, scroll_ulc_y;
  int header_height;
  PickCategoryLine contents;
  void scroll (HWND hwnd, int which, int *var, int code, int howmany);
  HWND ListHeader (void) const { return listheader; }
  void SetPackageFilter (const std::string &filterString) { packageFilterString = filterString; }

  class views
  {
  public:
    static const views Unknown;
    static const views PackageFull;
    static const views Package;
    static const views PackageKeeps;
    static const views PackageSkips;
    static const views Category;
    static const views NView;

    views ()
      :_value (0)
    {}
    views (int aInt)
    {
      _value = aInt;
      if (_value < 0 || _value > 5)
	_value = 0;
    }
    views & operator++ ();
    bool operator == (views const &rhs) { return _value == rhs._value; }
    bool operator != (views const &rhs) { return _value != rhs._value; }
    std::string caption ();

  private:
    int _value;
  };

  class Header
  {
  public:
    int resid;
    int width;
    int x;
    bool needs_clip;
  };

private:
  static ATOM WindowClassAtom;
  HWND listheader;
  views view_mode;
  bool showObsolete;
  std::string packageFilterString;

  // Stuff needed to handle resizing
  bool hasWindowRect;
  RECTWrapper lastWindowRect;
  int total_delta_x;

  int set_header_column_order (views vm);
  void set_headers ();
  void init_headers (HDC dc);
  void note_width (Header *hdrs, HDC dc, const std::string& string,
                   int addend, int column);
  HANDLE loadImage( int id );
};

bool isObsolete (std::set <std::string, casecompare_lt_op> &categories);
bool isObsolete (const std::string& catname);

#endif /* SETUP_PICKVIEW_H */
