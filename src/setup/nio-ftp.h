/*
 * Copyright (c) 2000, 2001, Red Hat, Inc.
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

#ifndef SETUP_NIO_FTP_H
#define SETUP_NIO_FTP_H

#include "netio.h"

/* Direct FTP (without proxy) */

class SimpleSocket;

class NetIO_FTP:public NetIO
{
  SimpleSocket *s;

public:
    NetIO_FTP (char const *url);
    virtual ~ NetIO_FTP ();

  /* If !ok() that means the transfer isn't happening. */
  virtual int ok ();

  /* Read `nbytes' bytes from the file.  Returns zero when the file
     is complete. */
  virtual ssize_t read (char *buf, size_t nbytes);
};

#endif /* SETUP_NIO_FTP_H */
