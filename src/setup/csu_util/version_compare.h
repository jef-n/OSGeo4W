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

#ifndef SETUP_VERSION_COMPARE_H
#define SETUP_VERSION_COMPARE_H

#include <string>

/* Sort two version numbers, comparing equivalently seperated strings of
 * digits numerically.
 *
 * Returns a positive number if (a > b)
 * Returns a negative number if (a < b)
 * Returns zero if (a == b)
 *
 * Inspired but not equivalent to rpmvercmp().
 */
int version_compare (std::string a, std::string b);
    
#endif /* SETUP_VERSION_COMPARE_H */
