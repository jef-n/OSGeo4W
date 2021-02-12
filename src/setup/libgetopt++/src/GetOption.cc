/*
 * Copyright (c) 2002 Robert Collins.
 *
 *     This program is free software; you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation; either version 2 of the License, or
 *     (at your option) any later version.
 *
 *     A copy of the GNU General Public License can be found at
 *     http://www.gnu.org/
 *
 * Written by Robert Collins <robertc@hotmail.com>
 *
 */

#if HAVE_CONFIG_H
#include "autoconf.h"
#endif
#include "getopt++/GetOption.h"
#include "getopt++/Option.h"

GetOption *GetOption::Instance = 0;

GetOption *GetOption::GetInstance ()
{
  if ( !Instance )
    {
      Instance = new GetOption();
      Instance->Init ();
    }

  return Instance;
}
