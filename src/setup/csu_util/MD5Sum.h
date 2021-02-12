/*
 * Copyright (c) 2004 Max Bowsher
 *
 *     This program is free software; you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation; either version 2 of the License, or
 *     (at your option) any later version.
 *
 *     A copy of the GNU General Public License can be found at
 *     http://www.gnu.org/
 *
 * Written by Max Bowsher
 */

#ifndef SETUP_MD5SUM_H
#define SETUP_MD5SUM_H

/*
 * A C++ wrapper for the libmd5-rfc library, which additionally provides
 * storage and comparison of MD5 checksums.
 *
 * An MD5Sum may be given a value in one of two ways:
 * 1. md5->set()
 * 2. md5->begin(); md5->append(); md5->finish();
 *
 * Once it has a value, md5->isSet() will return true,
 */

#include <string>

namespace libmd5_rfc {
  struct md5_state_s;
};

class MD5Sum
{
  public:
    MD5Sum() : state(Empty), internalData(0) {};
    MD5Sum(const MD5Sum& source);
    MD5Sum& operator= (const MD5Sum& source);
    ~MD5Sum();

    void set(const unsigned char digest[16]);
    void begin();
    void append(const unsigned char* data, int nbytes);
    void finish();

    bool isSet() const { return (state == Set); };
    operator std::string() const;
    std::string str() const { return (std::string)(*this); };
    bool operator == (const MD5Sum& other) const;
    bool operator != (const MD5Sum& other) const { return !(*this == other); };

  private:
    enum { Empty, Accumulating, Set } state;
    unsigned char digest[16];
    libmd5_rfc::md5_state_s* internalData;
};
    
#endif /* SETUP_MD5SUM_H */
