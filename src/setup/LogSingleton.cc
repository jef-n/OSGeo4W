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

#include "LogSingleton.h"
#include <stdexcept>

using namespace std;

/* Helper functions */

/* End of a Log comment */
ostream& endLog(ostream& outs)
{
  /* Doesn't seem to be any way around this */
  dynamic_cast<LogSingleton &>(outs).endEntry();
  return outs;
}

/* The LogSingleton class */

LogSingleton * LogSingleton::theInstance(0);

LogSingleton::LogSingleton(std::streambuf* aStream) : ios (aStream), ostream (aStream)
{
  ios::init (aStream);
}
LogSingleton::~LogSingleton(){}

LogSingleton &
LogSingleton::GetInstance()
{
  if (!theInstance)
    throw new invalid_argument ("No instance has been set!");
  return *theInstance;
}

void
LogSingleton::SetInstance(LogSingleton &newInstance)
{
  theInstance = &newInstance;
}

#if 0
// Logging class. Default logging level is PLAIN.
class LogSingleton : public ostream
{
public:
  // Singleton support
  /* Some platforms don't call destructors. So this call exists
   * which guarantees to flush any log data...
   * but doesn't call generic C++ destructors
   */
  virtual void exit (int const exit_code) __attribute__ ((noreturn));
  // get a specific verbosity stream.
  virtual ostream &operator() (enum log_level level);

  friend ostream& endLog(ostream& outs);

protected:
  LogSingleton (LogSingleton const &); // no copy constructor
  LogSingleton &operator = (LogSingleton const&); // no assignment operator
  void endEntry(); // the current in-progress entry is complete.
private:
  static LogSingleton *theInstance;
};
#endif
