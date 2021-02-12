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

#include "MD5Sum.h"
#include <stdexcept>
#include <string.h>

namespace libmd5_rfc {
#include "../libmd5-rfc/md5.h"
}

MD5Sum::MD5Sum(const MD5Sum& source)
{
  *this = source;
}

MD5Sum&
MD5Sum::operator= (const MD5Sum& source)
{
  state = source.state;
  memcpy(digest, source.digest, sizeof(digest));
  internalData = 0;
  if (source.internalData)
  {
    internalData = new libmd5_rfc::md5_state_s;
    *internalData = *(source.internalData);
  }
  return *this;
}

MD5Sum::~MD5Sum()
{
  if (internalData) delete internalData;
}

void
MD5Sum::set(const unsigned char digest[16])
{
  memcpy(this->digest, digest, sizeof(this->digest));
  state = Set;
  if (internalData) delete internalData;
}

void
MD5Sum::begin()
{
  if (internalData) delete internalData;
  internalData = new libmd5_rfc::md5_state_s;
  state = Accumulating;
  libmd5_rfc::md5_init(internalData);
}

void
MD5Sum::append(const unsigned char* data, int nbytes)
{
  if (!internalData)
    throw new std::logic_error("MD5Sum::append() called on an object not "
                               "in the 'Accumulating' state");
  libmd5_rfc::md5_append(internalData, data, nbytes);
}

void
MD5Sum::finish()
{
  if (!internalData)
    throw new std::logic_error("MD5Sum::finish() called on an object not "
                               "in the 'Accumulating' state");
  libmd5_rfc::md5_finish(internalData, digest);
  state = Set;
  delete internalData; internalData = 0;
}

MD5Sum::operator std::string() const
{
  char hexdigest[33];
  hexdigest[32] = '\0';

  for (int i = 0; i < 16; ++i)
  {
    int hexdigit = 2 * i;
    char tmp;
    
    tmp = digest[i] >> 4;
    hexdigest[hexdigit] =     (tmp < 10) ? (tmp + '0') : (tmp + 'a' - 10);

    tmp = digest[i] & 0x0f;
    hexdigest[hexdigit + 1] = (tmp < 10) ? (tmp + '0') : (tmp + 'a' - 10);
  }

  return std::string(hexdigest);
}

bool
MD5Sum::operator == (const MD5Sum& other) const
{
  if (state != Set || other.state != Set)
    throw new std::logic_error("MD5Sum comparison attempted on operands not "
                               "in the 'Set' state");
  return (memcmp(digest, other.digest, sizeof(digest)) == 0);
}
