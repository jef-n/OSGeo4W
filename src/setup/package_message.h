/*
 * Copyright (c) Christopher Faylor
 *
 *     This program is free software; you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation; either version 2 of the License, or
 *     (at your option) any later version.
 *
 *     A copy of the GNU General Public License can be found at
 *     http://www.gnu.org/
 */

#ifndef SETUP_PACKAGE_MESSAGE_H
#define SETUP_PACKAGE_MESSAGE_H

#include "UserSettings.h"
#include "state.h"
#include <stdlib.h>
#include "win32.h"

class packagemessage
{
  std::string id;
  std::string message;
public:
  packagemessage (): id (""), message ("") {}
  void set (const std::string& in_id, const std::string& in_message)
  {
    id = in_id;
    message = in_message;
  }
  void display ()
  {
    if (unattended_mode || !id.length () || UserSettings::instance().get (id.c_str ()))
      /* No message or already seen */;
    else if (MessageBox (NULL, message.c_str (), "Setup Alert",
			 MB_OKCANCEL | MB_ICONSTOP | MB_SETFOREGROUND
			 | MB_TOPMOST) != IDCANCEL)
      UserSettings::instance().set (id.c_str (), "1");
    else
      exit (1);
  }
};

#endif /* SETUP_PACKAGE_MESSAGE_H */

