/*
 * Copyright (c) 2003 Robert Collins.
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

#ifndef SETUP_GENERIC_H
#define SETUP_GENERIC_H

/* Todo fully paramterise */
template <class _Visitor, class _Predicate>
struct _visit_if {
  _visit_if(_Visitor v, _Predicate p) : visitor(v), predicate (p) {}
  void operator() (typename _Visitor::argument_type& arg) {
    if (predicate(arg))
      visitor(arg);
  }
  _Visitor visitor;
  _Predicate predicate;
};

template <class _Visitor, class _Predicate>
_visit_if<_Visitor, _Predicate>
visit_if(_Visitor visitor, _Predicate predicate)
{
  return _visit_if<_Visitor, _Predicate>(visitor, predicate);
}

#endif /* SETUP_GENERIC_H */
