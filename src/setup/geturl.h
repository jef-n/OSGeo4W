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

#ifndef SETUP_GETURL_H
#define SETUP_GETURL_H

/* Download files from the Internet.  These pop up a progress dialog;
   don't forget to dismiss it when you're done downloading for a while */

#include <string>

extern size_t total_download_bytes;
extern size_t total_download_bytes_sofar;

class io_stream;

io_stream *get_url_to_membuf (const std::string &_url, HWND owner, bool nocache = false);
std::string get_url_to_string (const std::string &_url, HWND owner, bool nocache = false);
int get_url_to_file (const std::string &_url, const std::string &_filename,
                     size_t expected_size, HWND owner, bool nocache = false);

#endif /* SETUP_GETURL_H */
