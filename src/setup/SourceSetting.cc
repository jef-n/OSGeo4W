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

#include "SourceSetting.h"
#include "UserSettings.h"
#include "io_stream.h"
#include "state.h"
#include "resource.h"
#include "String++.h"

void
SourceSetting::load()
{
  const char *fg_ret;
  if (( fg_ret = UserSettings::instance().get ("last-action") ))
    source = sourceFromString(fg_ret);
}

void
SourceSetting::save()
{
  switch (source)
    {
    case IDC_SOURCE_DOWNLOAD:
      UserSettings::instance().set ("last-action", "Download");
      break;
    case IDC_SOURCE_NETINST:
      UserSettings::instance().set ("last-action", "Download,Install");
      break;
    case IDC_SOURCE_CWD:
      UserSettings::instance().set ("last-action", "Install");
      break;
    default:
      break;
    }
}

int
SourceSetting::sourceFromString(const std::string& aSource)
{
  if (!casecompare(aSource, "Download"))
    return IDC_SOURCE_DOWNLOAD;
  if (!casecompare(aSource, "Download,Install"))
    return IDC_SOURCE_NETINST;
  if (!casecompare(aSource, "Install"))
    return IDC_SOURCE_CWD;

  /* A sanish default */
  return IDC_SOURCE_NETINST;
}
