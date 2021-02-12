/*
 * Copyright (c) 2003, Robert Collins <rbtcollins@hotmail.com>
 *
 *     This program is free software; you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation; either version 2 of the License, or
 *     (at your option) any later version.
 *
 *     A copy of the GNU General Public License can be found at
 *     http://www.gnu.org/
 *
 * Written by Robert Collins.
 *
 */

#ifndef SETUP_CONNECTIONSETTING_H
#define SETUP_CONNECTIONSETTING_H

// This is the header for the ConnectionSetting class, which persists and reads
// in user settings to decide how setup should connect...

#include <string>

class ConnectionSetting
{
  public:
    ConnectionSetting ();
    ~ConnectionSetting ();
  private:
    int typeFromString(const std::string& aType);
};

#endif /* SETUP_CONNECTIONSETTING_H */
