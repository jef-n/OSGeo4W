/*
 * Copyright (c) 2001, 2002, Robert Collins.
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

/* this is the parent class for all IO operations. It's flexable enough to be cover for
 * HTTP access, local file access, and files being extracted from archives.
 * It also encapsulates the idea of an archive, and all non-archives become the special 
 * case.
 */

#if 0
static const char *cvsid =
  "\n%%% $Id: io_stream.cc,v 2.24 2011/04/21 09:31:37 jturney Exp $\n";
#endif

#include "LogSingleton.h"

#include "io_stream.h"

#include <stdexcept>
#include "IOStreamProvider.h"
#include <map>
#include "String++.h"

using namespace std;

typedef map <std::string, IOStreamProvider *, casecompare_lt_op> providersType;
static providersType *providers;
static size_t longestPrefix = 0;
static int inited = 0;
  
void
io_stream::registerProvider (IOStreamProvider &theProvider,
			     const std::string& urlPrefix)
{
  if (!inited)
    {
      providers = new providersType;
      inited = true;
    }
  theProvider.key = urlPrefix;
  if (providers->find (urlPrefix) != providers->end())
    throw new invalid_argument ("urlPrefix already registered!");
  (*providers)[urlPrefix] = &theProvider;
  if (urlPrefix.size() > longestPrefix)
    longestPrefix = urlPrefix.size();
}

static IOStreamProvider const *
findProvider (const std::string& path)
{
  if (path.size() < longestPrefix)
    return NULL;
  for (providersType::const_iterator i = providers->begin();
       i != providers->end(); ++i)
    {
      if (!casecompare(path, i->first, i->first.size()))
       	return i->second;
    }
  return NULL;
}

/* Static members */
io_stream *
io_stream::factory (io_stream * parent)
{
  /* something like,  
   * if !next_file_name 
   *   return NULL
   * switch (magic_id(peek (parent), max_magic_length))
   * case io_stream * foo = new tar
   * case io_stream * foo = new bz2
   * return foo
   */
  log (LOG_TIMESTAMP) <<  "io_stream::factory has been called" << endLog;
  return NULL;
}

#define url_scheme_not_registered(name) \
    throw new invalid_argument ((std::string("URL Scheme for '")+ \
				  name+"' not registered!").c_str())

io_stream *
io_stream::open (const std::string& name, const std::string& mode)
{
  IOStreamProvider const *p = findProvider (name);
  if (!p)
    url_scheme_not_registered (name);
  io_stream *rv = p->open (&name.c_str()[p->key.size()], mode);
  if (!rv->error ())
    return rv;
  delete rv;
  return NULL;
}

int
io_stream::mkpath_p (path_type_t isadir, const std::string& name)
{
  IOStreamProvider const *p = findProvider (name);
  if (!p)
    url_scheme_not_registered (name);
  return p->mkdir_p (isadir, &name.c_str()[p->key.size()]);
}

/* remove a file or directory. */
int
io_stream::remove (const std::string& name)
{
  IOStreamProvider const *p = findProvider (name);
  if (!p)
    url_scheme_not_registered (name);
  return p->remove (&name.c_str()[p->key.size()]);
}

int
io_stream::mklink (const std::string& from, const std::string& to,
		   io_stream_link_t linktype)
{
  log (LOG_BABBLE) << "io_stream::mklink (" << from << "->" << to << ")"
    << endLog;
  IOStreamProvider const *fromp = findProvider (from);
  IOStreamProvider const *top = findProvider (to);
  if (!fromp)
    url_scheme_not_registered (from);
  if (!top)
    url_scheme_not_registered (to);
  if (fromp != top)
    throw new invalid_argument ("Attempt to link across url providers.");
  return fromp->mklink (&from.c_str()[fromp->key.size()], 
    			&to.c_str()[top->key.size()], linktype);
}

int
io_stream::move_copy (const std::string& from, const std::string& to)
{
  /* parameters are ok - checked before calling us, and we are private */
  io_stream *in = io_stream::open (to, "wb");
  io_stream *out = io_stream::open (from, "rb");
  if (io_stream::copy (in, out))
    {
      log (LOG_TIMESTAMP) << "Failed copy of " << from << " to " << to
	<< endLog;
      delete out;
      io_stream::remove (to);
      delete in;
      return 1;
    }
  /* TODO:
     out->set_mtime (in->get_mtime ());
   */
  delete in;
  delete out;
  io_stream::remove (from);
  return 0;
}

ssize_t io_stream::copy (io_stream * in, io_stream * out)
{
  if (!in || !out)
    return -1;
  char
    buffer[16384];
  ssize_t
    countin,
    countout;
  while ((countin = in->read (buffer, 16384)) > 0)
    {
      countout = out->write (buffer, countin);
      if (countout != countin)
	{
	  log (LOG_TIMESTAMP) << "io_stream::copy failed to write "
	    << countin << " bytes" << endLog;
	  return countout ? countout : -1;
	}
    }

  /*
    Loop above ends with countin = 0 if we have reached EOF, or -1 if an
    read error occurred.
  */
  if (countin < 0)
    return -1;

   /* Here it would be nice to be able to do something like
     TODO:
     out->set_mtime (in->get_mtime ());
   */
  return 0;
}

int
io_stream::move (const std::string& from, const std::string& to)
{
  IOStreamProvider const *fromp = findProvider (from);
  IOStreamProvider const *top = findProvider (to);
  if (!fromp)
    url_scheme_not_registered (from);
  if (!top)
    url_scheme_not_registered (to);
  if (fromp != top)
    return io_stream::move_copy (from, to);
  return fromp->move (&from.c_str()[fromp->key.size()],
  		      &to.c_str()[top->key.size()]);
}

char *
io_stream::gets (char *buffer, size_t length)
{
  char *pos = buffer;
  size_t count = 0;
  while (count + 1 < length && read (pos, 1) == 1)
    {
      count++;
      pos++;
      if (*(pos - 1) == '\n')
	{
	  --pos; /* end of line, remove from buffer */
	  if (pos > buffer && *(pos - 1) == '\r')
	    --pos;
	  break;
	}
    }
  if (count == 0 || error ())
    /* EOF when no chars found, or an error */
    return NULL;
  *pos = '\0';
  return buffer;
}

int
io_stream::exists (const std::string& name)
{
  IOStreamProvider const *p = findProvider (name);
  if (!p)
    url_scheme_not_registered (name);
  return p->exists (&name.c_str()[p->key.size()]);
}

/* virtual members */

io_stream::~io_stream () {}
