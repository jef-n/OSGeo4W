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

#ifndef SETUP_IO_STREAM_CYGFILE_H
#define SETUP_IO_STREAM_CYGFILE_H

#include "io_stream.h"


/* io_stream on disk files using cygwin paths
 * and potentially understanding links in the future
 */

extern int cygmkdir_p (path_type_t isadir, const std::string& path);

class io_stream_cygfile:public io_stream
{
public:
  static int exists (const std::string& );
  static int remove (const std::string& );
  static int mklink (const std::string& , const std::string& , io_stream_link_t);
    io_stream_cygfile (const std::string&, const std::string&);
    virtual ~ io_stream_cygfile ();
  /* read data (duh!) */
  virtual ssize_t read (void *buffer, size_t len);
  /* provide data to (double duh!) */
  virtual ssize_t write (const void *buffer, size_t len);
  /* read data without removing it from the class's internal buffer */
  virtual ssize_t peek (void *buffer, size_t len);
  virtual ssize_t tell ();
  virtual int seek (long where, io_stream_seek_t whence);
  /* can't guess, oh well */
  virtual int error ();
  virtual int set_mtime (time_t);
  /* not relevant yet */
  virtual time_t get_mtime () { return 0; }
  virtual size_t get_size ();
  static int move (const std::string& ,const std::string& );
  static std::string normalise (const std::string& unixpath);
private:
  /* always require parameters */
  io_stream_cygfile () {}
  friend int cygmkdir_p (path_type_t isadir, const std::string& _name);
  FILE *fp;
  int lasterr;
  std::string fname;
  static std::string cwd;
};

#endif /* SETUP_IO_STREAM_CYGFILE_H */
