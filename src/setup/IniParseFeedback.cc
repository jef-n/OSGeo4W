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

#include "IniParseFeedback.h"

IniParseFeedback::~IniParseFeedback(){}

void IniParseFeedback::progress(unsigned long const, unsigned long const) {}
void IniParseFeedback::iniName (const std::string& ) {}
void IniParseFeedback::babble(const std::string& ) const {}
void IniParseFeedback::warning (const std::string& ) const {}
void IniParseFeedback::error(const std::string& ) const {}
