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

#ifndef SETUP_LOGSINGLETON_H
#define SETUP_LOGSINGLETON_H

#if defined(__GNUC__)
#define NORETURN __attribute__ ((noreturn))
#elif defined(_MSC_VER)
#define NORETURN __declspec(noreturn)
#else
#define NORETURN
#endif

#include <iostream>

enum log_level {
  LOG_PLAIN = 2,
  LOG_BABBLE = 1,
  LOG_TIMESTAMP	= 2
};

// Logging class. Default logging level is PLAIN.
class LogSingleton : public std::ostream
{
public:
  // Singleton support
  static LogSingleton &GetInstance();
  static void SetInstance(LogSingleton &anInstance);

  /* Some platforms don't call destructors. So this call exists
   * which guarantees to flush any log data...
   * but doesn't call generic C++ destructors
   */
  NORETURN virtual void exit (int const exit_code) = 0;
  virtual ~LogSingleton();
  // get a specific verbosity stream.
  virtual std::ostream &operator() (enum log_level level) = 0;

  friend std::ostream& endLog(std::ostream& outs);

protected:
  LogSingleton(std::streambuf* aStream); // Only child classs can be created.
  LogSingleton (LogSingleton const &); // no copy constructor
  LogSingleton &operator = (LogSingleton const&); // no assignment operator
  virtual void endEntry() = 0; // the current in-progress entry is complete.
private:
  static LogSingleton *theInstance;
};

/* End of a Log comment */
extern std::ostream& endLog(std::ostream& outs);
//extern ostream& endLog(ostream& outs);

#define log(X) LogSingleton::GetInstance()(X)
#endif /* SETUP_LOGSINGLETON_H */
