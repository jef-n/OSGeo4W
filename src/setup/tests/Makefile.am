## Process this file with automake to produce Makefile.in
#
# $Id: Makefile.am,v 1.2 2007/07/30 22:55:50 briand Exp $
#
# Copyright (c) 2002, Robert Collins
#
#     This program is free software; you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation; either version 2 of the License, or
#     (at your option) any later version.
#
#     A copy of the GNU General Public License can be found at
#     http://www.gnu.org/
#
# Written by Robert Collins  <rbtcollins@hotmail.com>
#
# Makefile for Cygwin installer tests

AUTOMAKE_OPTIONS = dist-bzip2 subdir-objects 1.6 foreign

# We would like to use -Winline for C++ as well, but some STL code triggers
# this warning. (Bug verified present in gcc-3.3)
AM_CXXFLAGS	= -Werror -Wall -Wpointer-arith -Wcomments \
  -Wcast-align -Wwrite-strings -Wstrict-prototypes -Wmissing-prototypes
AM_CFLAGS	= $(AM_CXXFLAGS) -Wmissing-declarations -Winline

AM_CPPFLAGS = -I. -I$(srcdir) -I$(top_srcdir)

check_PROGRAMS = \
	UserSettingTest \
	UserSettingsTest
	
TESTS = \
	UserSettingTest \
	UserSettingsTest
	
UserSettingTest_SOURCES = UserSettingTest.cc
UserSettingTest_CXXFLAGS = -DASTEST
UserSettingTest_LDADD = \
	$(top_builddir)/Exception.o \
	$(top_builddir)/UserSetting.o \
	$(top_builddir)/UserSettings.o \
	$(top_builddir)/String++.o
	
UserSettingsTest_SOURCES = UserSettingsTest.cc UserSettingTest.cc
UserSettingsTest_LDADD = \
	$(top_builddir)/Exception.o \
	$(top_builddir)/UserSetting.o \
	$(top_builddir)/UserSettings.o \
	$(top_builddir)/String++.o