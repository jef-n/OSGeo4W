/*
 * Copyright (c) 2001, Robert Collins.
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

#ifndef SETUP_ARCHIVE_H
#define SETUP_ARCHIVE_H

/* this is the parent class for all archive IO operations. */

/* The read/write the archive stream to get the archive data is flawed.
 * The problem is that you then need a *different* gzip etc class to be able
 * to ungzip a gzip from within an archive.
 * The correct way is to
 * 1) retrieve the file name.
 * 2) the user creates their own output object.
 * 3) the user calls extract_file (output strea,).
 */

typedef enum
{
  ARCHIVE_FILE_INVALID,
  ARCHIVE_FILE_REGULAR,
  ARCHIVE_FILE_HARDLINK,
  ARCHIVE_FILE_SYMLINK,
  ARCHIVE_FILE_DIRECTORY
}
archive_file_t;


class archive:public io_stream
{
public:
  enum extract_results
  {
    extract_inuse = 7,		/* Arbitrary number != 1 */
    extract_ok = 0,
    extract_other = 9
  };
  /* get an archive child class from an io_stream */
  static archive *extract (io_stream *);
  /* get an ouput stream for the next files from the archive.
   * returns NULL on failure.
   * The stream is not taken over - it will not be automatically deleted
   */
  virtual io_stream *extract_file () = 0;
  /* extract the next file to the given prefixURL+Path in one step, and name it with the
   * given suffix.
   * returns 1 on failure.
   */
  static extract_results extract_file (archive *, const std::string&,
				       const std::string&,
				       const std::string = std::string());

  /*
   * To create a stream that will be compressed, you should open the url, and then get a new stream
   * from compress::compress.
   */
  /* read data - not valid for archives (duh!)
   * Could be made valid via the read-child-directly model
   */
//  virtual ssize_t read(void *buffer, size_t len) {return -1;};
  /* provide data to (double duh!) */
//  virtual ssize_t write(void *buffer, size_t len) { return -1;};
  /* read data without removing it from the class's internal buffer */
//  virtual ssize_t peek(void *buffer, size_t len);
//  virtual ssize_t tell ();
  /* try guessing this one */
//  virtual int error ();
  /* Find out the next stream name -
   * ie for foo.tar.gz, at offset 0, next_file_name = foo.tar
   * for foobar that is an compress, next_file_name is the next
   * extractable filename.
   * The way this works is that when read returns 0, you are at the end of *a* file.
   * next_file_name will allow read to be called again, if it returns !NULL
   */
  virtual const std::string next_file_name () = 0;
  virtual archive_file_t next_file_type () = 0;
  virtual const std::string linktarget () = 0;
  virtual int skip_file () = 0;
  /* if you are still needing these hints... give up now! */
  virtual ~archive() = 0;
protected:
  void operator= (const archive &);
  archive () {};
  archive (const archive &);
private:
//  archive () {};
};

#endif /* SETUP_ARCHIVE_H */
