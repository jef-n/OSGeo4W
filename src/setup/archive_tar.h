/*
 * Copyright (c) 2000, Red Hat, Inc.
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
 * Written by DJ Delorie <dj@cygnus.com>
 * Made OOP by R Collins <rbtcollins@hotmail.com>
 *
 */

#ifndef SETUP_ARCHIVE_TAR_H
#define SETUP_ARCHIVE_TAR_H

#include "io_stream.h"
#include "archive.h"
#include "win32.h"

typedef struct
{
  char name[100];		/*   0 */
  char mode[8];			/* 100 */
  char uid[8];			/* 108 */
  char gid[8];			/* 116 */
  char size[12];		/* 124 */
  char mtime[12];		/* 136 */
  char chksum[8];		/* 148 */
  char typeflag;		/* 156 */
  char linkname[100];		/* 157 */
  char magic[6];		/* 257 */
  char version[2];		/* 263 */
  char uname[32];		/* 265 */
  char gname[32];		/* 297 */
  char devmajor[8];		/* 329 */
  char devminor[8];		/* 337 */
  char prefix[155];		/* 345 */
  char junk[12];		/* 500 */
}
tar_header_type;

typedef struct tar_map_result_type_s
{
  struct tar_map_result_type_s *next;
  std::string stored_name;
  std::string mapped_name;
}
tar_map_result_type;

class tar_state
{
public:
  tar_state ():lasterr (0), eocf (0), have_longname ('\0'), file_offset (0),
    file_length (0), header_read (0)
  {
    parent = NULL;
    filename[0] = '\0';
    tar_map_result = NULL;
  };
  io_stream *parent;
  int lasterr;
  int eocf;
  char have_longname;
  /* where in the current file are we? */
  size_t file_offset;
  size_t file_length;
  int header_read;
  tar_header_type tar_header;
  char filename[MAX_PATH + 512];
  tar_map_result_type *tar_map_result;
};

class archive_tar_file:public io_stream
{
private:
  bool read_something;
public:
  archive_tar_file (tar_state &);
  virtual ssize_t read (void *buffer, size_t len);
  /* provide data to (double duh!) */
  virtual ssize_t write (const void *buffer, size_t len);
  /* read data without removing it from the class's internal buffer */
  virtual ssize_t peek (void *buffer, size_t len);
  virtual ssize_t tell ();
  virtual int seek (long where, io_stream_seek_t whence);
  /* try guessing this one */
  virtual int error ();
  virtual time_t get_mtime ();
  virtual size_t get_size () {return state.file_length;}
  virtual int set_mtime (time_t) { return 1; }
  virtual ~ archive_tar_file ();
private:
    tar_state & state;
};

class archive_tar:public archive
{
public:
  archive_tar (io_stream * original);
  virtual io_stream *extract_file ();
  /* read data (duh!) */
  virtual ssize_t read (void *buffer, size_t len);
  /* provide data to (double duh!) */
  virtual ssize_t write (const void *buffer, size_t len);
  /* read data without removing it from the class's internal buffer */
  virtual ssize_t peek (void *buffer, size_t len);
  virtual ssize_t tell ();
  virtual int seek (long where, io_stream_seek_t whence);
  /* try guessing this one */
  virtual int error ();
  /* Find out the next stream name -
   * ie for foo.tar.gz, at offset 0, next_file_name = foo.tar
   * for foobar that is an compress, next_file_name is the next
   * extractable filename.
   */
  virtual const std::string next_file_name ();
  virtual archive_file_t next_file_type ();
  /* returns the mtime of the archive file, not of the current file */
  virtual time_t get_mtime ();
  /* nonsense for a tarball */
  virtual size_t get_size () {return 0;};
  /* only of use when we support writing to tar */
  virtual int set_mtime (time_t) { return 1; }
  virtual const std::string linktarget ();
  virtual int skip_file ();
  /* if you are still needing these hints... give up now! */
  virtual ~ archive_tar ();
  archive_tar& operator= (const archive_tar &);
  archive_tar (archive_tar const &);
private:
  archive_tar () {}
  tar_state state;
  unsigned int archive_children;
};

/* Only one tarfile may be open at a time.  gzipped files handled
   automatically */

/* returns zero on success, nonzero on failure */
//int   tar_open (const char *pathname);

/* pass adjusted path, returns zero on success, nonzero on failure */
//int   tar_read_file (char *path);


#if 0
/* pass path to tar file and from/to pairs for path prefix (NULLs at
   end , returns zero if completely successful, nonzero (counts
   errors) on failure */
int tar_auto (char *pathname, char **map);
#endif


//int   tar_mkdir_p (int isadir, char *path);

/*
extern int _tar_verbose;
extern FILE * _tar_vfile;
*/

#endif /* SETUP_ARCHIVE_TAR_H */
