/*
 * Copyright (c) 2003, Robert Collins
 *
 *     This program is free software; you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation; either version 2 of the License, or
 *     (at your option) any later version.
 *
 *     A copy of the GNU General Public License can be found at
 *     http://www.gnu.org/
 *
 * Written by Robert Collins <rbtcollins@hotmail.com>
 *
 */

#if 0
static const char *cvsid =
  "\n%%% $Id: UserSettingTest.cc,v 1.1 2003/07/26 07:08:43 rbcollins Exp $\n";
#endif

#include "site.h"
#include "win32.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <process.h>
#include <algorithm>

#include "LogSingleton.h"
#include "io_stream.h"

#include "port.h"
#include "Exception.h"
#include "UserSetting.h"
#include "UserSettings.h"

using namespace std;

class TestSetting : public UserSetting {
  public:
  TestSetting();
  static TestSetting &getInstance();
  virtual void load();
  virtual void save();
  void testPassed();
  private:
  static TestSetting Instance;
  bool loaded;
  bool saved;
};

TestSetting &
TestSetting::getInstance()
{
 return Instance;
}

TestSetting TestSetting::Instance;

TestSetting::TestSetting() : loaded(false), saved(false) {}

void
TestSetting::load()
{
 loaded = true;
}

void
TestSetting::save()
{
 saved = true;
}

void
TestSetting::testPassed()
{
 if (saved)
 exit(1);
 if(loaded)
 exit(1);
}

#ifdef ASTEST
int
main (int argc, char **argv)
{
  TestSetting::getInstance().testPassed();
  return 0;
}
#endif
