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

#ifndef SETUP_NIO_FILE_H
#define SETUP_NIO_FILE_H

/* see nio-file.cc */

class NetIO_File:public NetIO
{
public:
  NetIO_File (char const *url);
  void *fd;
   ~NetIO_File ();
  virtual int ok ();
  virtual ssize_t read (char *buf, size_t nbytes);
};

#endif /* SETUP_NIO_FILE_H */
