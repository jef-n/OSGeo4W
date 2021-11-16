## Process this file with automake to produce Makefile.in
#
# $Id$
#

AUTOMAKE_OPTIONS = subdir-objects 1.9 foreign
# -Wno-uninitialized added to deal with g++ 3.4.4's spurious STL warnings
# (http://gcc.gnu.org/bugzilla/show_bug.cgi?id=22207)
AM_CXXFLAGS = -Wall -Werror -Wno-uninitialized
##DIST_SUBDIRS	= src
##SUBDIRS		= src

EXTRA_DIST = \
  bootstrap.sh

DISTCLEANFILES = include/stamp-h include/stamp-h[0-9]*

AM_CPPFLAGS = -I$(top_srcdir)/include

getoptincludedir = $(includedir)/getopt++

lib_LTLIBRARIES = libgetopt++.la
check_PROGRAMS = tests/OptionSet tests/testoption tests/optioniterator tests/BoolOptionTest

TESTS = tests/OptionSet tests/optioniterator tests/BoolOptionTest

libgetopt___la_SOURCES = src/GetOption.cc src/Option.cc src/BoolOption.cc \
	src/OptionSet.cc \
	src/StringArrayOption.cc src/StringOption.cc

libgetopt___la_LDFLAGS = -version-info 1:1:0 -no-undefined

getoptinclude_HEADERS = include/getopt++/Option.h \
  include/getopt++/BoolOption.h \
  include/getopt++/DefaultFormatter.h \
  include/getopt++/GetOption.h \
  include/getopt++/OptionSet.h \
  include/getopt++/StringArrayOption.h \
  include/getopt++/StringOption.h

tests_testoption_SOURCES = tests/testoption.cc
tests_testoption_LDADD = libgetopt++.la

tests_optioniterator_SOURCES = tests/optioniterator.cc
tests_optioniterator_LDADD = libgetopt++.la

tests_BoolOptionTest_SOURCES = tests/BoolOptionTest.cc
tests_BoolOptionTest_LDADD = libgetopt++.la

tests_OptionSet_SOURCES = tests/OptionSet.cc
tests_OptionSet_LDADD = libgetopt++.la
