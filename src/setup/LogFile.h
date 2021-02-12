/*
 * Copyright (c) 2002, Robert Collins..
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

#ifndef SETUP_LOGFILE_H
#define SETUP_LOGFILE_H

#if defined(__GNUC__)
#define NORETURN __attribute__ ((noreturn))
#elif defined(_MSC_VER)
#define NORETURN __declspec(noreturn)
#else
#define NORETURN
#endif

#include "LogSingleton.h"
#include <sstream>

// Logging class. Default logging level is PLAIN.
class LogFile : public LogSingleton {
public:
  static LogFile *createLogFile();
  LogFile();
  void clearFiles(); // delete all target filenames
  void setFile (int minlevel, const std::string& path, bool append);
  std::string getFileName (int level) const;
  /* Some platforms don't call destructors. So this call exists
   * which guarantees to flush any log data...
   * but doesn't call generic C++ destructors
   */
  NORETURN virtual void exit (int const exit_code);
  virtual ~LogFile();
  // get a specific verbosity stream.
  virtual std::ostream &operator() (enum log_level level);
  
protected:
  LogFile(std::stringbuf *aStream);
  LogFile (LogFile const &); // no copy constructor
  LogFile &operator = (LogFile const&); // no assignment operator
  virtual void endEntry(); // the current in-progress entry is complete.
private:
  void log_save (int babble, const std::string& filename, bool append);
};

#endif /* SETUP_LOGFILE_H */
