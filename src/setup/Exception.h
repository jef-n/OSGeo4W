/*
 * Copyright (c) 2001, Robert Collins.
 *
 *     This program is free software; you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation; either version 2 of the License, or
 *     (at your option) any later version.
 *
 *     A copy of the GNU General Public License can be found at
 *     http://www.gnu.org/
 *
 * Written by Robert Collins  <rbtcollins@hotmail.com>
 *
 */

#ifndef SETUP_EXCEPTION_H
#define SETUP_EXCEPTION_H

#include <exception>
#include <string>
#include <typeinfo>
#include "msg.h"

class Exception : public std::exception {
public:
  Exception (char const *where, char const *message, int appErrNo = 0);
  Exception (char const *where, const std::string& message, int appErrNo = 0);
  ~Exception () throw() {};
  char const *what() const throw();
  int errNo() const;
private:
  std::string _message;
  int appErrNo;
};

#define APPERR_CORRUPT_PACKAGE	1
#define APPERR_IO_ERROR		2
#define APPERR_LOGIC_ERROR	3

#define TOPLEVEL_CATCH(threadname)                                      \
  catch (Exception *e)                                                  \
  {                                                                     \
    fatal(NULL, IDS_UNCAUGHT_EXCEPTION_WITH_ERRNO, (threadname),        \
        typeid(*e).name(), e->what(), e->errNo());                      \
  }                                                                     \
  catch (std::exception *e)                                             \
  {                                                                     \
    fatal(NULL, IDS_UNCAUGHT_EXCEPTION, (threadname),                   \
        typeid(*e).name(), e->what());                                  \
  }


#endif /* SETUP_EXCEPTION_H */
