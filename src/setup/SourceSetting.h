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

#ifndef SETUP_SOURCESETTING_H
#define SETUP_SOURCESETTING_H

// This is the header for the SourceSetting class, which persists and reads
// in user settings to decide what setup should be trying to do...

#include <string>

class SourceSetting
{
  public:
    SourceSetting () { load(); }
    ~SourceSetting () {}
    void load(void);
    void save(void);
  private:
    int sourceFromString(const std::string& aSource);
};

#endif /* SETUP_SOURCESETTING_H */
