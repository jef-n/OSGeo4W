/*
 * Copyright (c) 2000, Red Hat, Inc.
 *
 *     This program is free software; you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation; either version 2 of the License, or
 *     (at your option) any later version.
 *
 *     A copy of the GNU General Public License can be found at
 *     http://www.gnu.org/
 *
 * Written by DJ Delorie <dj@cygnus.com>
 *
 */

#include "Exception.h" 

Exception::Exception (char const *where, char const *message, int _appErrNo) : _message (message), appErrNo (_appErrNo)
{
}

Exception::Exception (char const *where, const std::string& message,
                      int _appErrNo)
  : appErrNo (_appErrNo)
{
  _message = message;
}

char const *
Exception::what() const throw()
{
  return _message.c_str ();
}

int
Exception::errNo() const
{
  return appErrNo;
}
