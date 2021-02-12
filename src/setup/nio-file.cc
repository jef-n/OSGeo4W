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

/* The purpose of this file is to manage access to files stored on the
   local disk (i.e. "downloading" setup.ini).  Called from netio.cc */

#if 0
static const char *cvsid =
  "\n%%% $Id: nio-file.cc,v 2.7 2006/04/15 21:21:25 maxb Exp $\n";
#endif

#include "win32.h"
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
#include "netio.h"
#include "nio-file.h"
#include "resource.h"
#include "msg.h"
#include "filemanip.h"

NetIO_File::NetIO_File (char const *Purl):
NetIO (Purl)
{
  fd = fopen (path, "rb");
  if (fd)
    {
      file_size = get_file_size (std::string("file://") + path);
    }
  else
    {
      const char *err = strerror (errno);
      if (!err)
	err = "(unknown error)";
      note (NULL, IDS_ERR_OPEN_READ, path, err);
    }
}

NetIO_File::~NetIO_File ()
{
  if (fd)
    fclose ((FILE *) fd);
}

int
NetIO_File::ok ()
{
  return fd ? 1 : 0;
}

ssize_t
NetIO_File::read (char *buf, size_t nbytes)
{
  return fread (buf, 1, nbytes, (FILE *) fd);
}
