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

#ifndef SETUP_INIPARSEFEEDBACK_H
#define SETUP_INIPARSEFEEDBACK_H


#include <string>
/* Strategy for feedback from IniParsing.
 * Used by the builder or parsing classes to send feedback that users need
 * but that should not interrupt parsing.
 * Fatal errors are thrown as exceptions.
 */
class IniParseFeedback
{
public:
  virtual void progress (unsigned long const, unsigned long const);
  virtual void iniName (const std::string& );
  virtual void babble (const std::string& ) const;
  virtual void warning (const std::string& ) const;
  virtual void error (const std::string& ) const;
  virtual ~ IniParseFeedback ();
};

#endif /* SETUP_INIPARSEFEEDBACK_H */
