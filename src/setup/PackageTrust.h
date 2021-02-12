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

#ifndef SETUP_PACKAGETRUST_H
#define SETUP_PACKAGETRUST_H

/* Used for selecting a given 'trust' level */
typedef enum
{
  TRUST_UNKNOWN,
  TRUST_PREV,
  TRUST_CURR,
  TRUST_TEST,
  NTRUST
}
trusts;

#endif /* SETUP_PACKAGETRUST_H */
