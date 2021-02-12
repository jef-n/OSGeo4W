/*
 * Copyright (c) 2002, Robert Collins.
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

#ifndef SETUP_IOSTREAMPROVIDER_H
#define SETUP_IOSTREAMPROVIDER_H

#include "io_stream.h"

/* An IOStreamProvider provides the interface for io_stream::open and 
 * related calls to operate.
 */

class IOStreamProvider
{
public:
  virtual int exists (const std::string& ) const = 0;
  virtual int remove (const std::string& ) const = 0;
  virtual int mklink (const std::string&, const std::string&,
                      io_stream_link_t) const = 0;
  virtual io_stream *open (const std::string&, const std::string&) const = 0;
  virtual ~IOStreamProvider (){}
  virtual int move (const std::string&, const std::string&) const = 0;
  virtual int mkdir_p (path_type_t isadir, const std::string& path) const = 0;
  std::string key; // Do not set - managed automatically.
protected:
  IOStreamProvider(){} // no base instances
  IOStreamProvider(IOStreamProvider const &); // no copy cons
  IOStreamProvider &operator=(IOStreamProvider const &); // no assignment
};

#endif /* SETUP_IOSTREAMPROVIDER_H */
