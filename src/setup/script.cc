/*
 * Copyright (c) 2001, Jan Nieuwenhuizen.
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
 *            Jan Nieuwenhuizen <janneke@gnu.org>
 *
 */

/* The purpose of this file is to provide functions for the invocation
   of install scripts. */

#if 0
static const char *cvsid =
  "\n%%% $Id: script.cc,v 2.41 2013/06/26 09:16:52 corinna Exp $\n";
#endif

#include "win32.h"
#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include "LogSingleton.h"
#include "filemanip.h"
#include "mount.h"
#include "io_stream.h"
#include "script.h"
#include "mkdir.h"
#include "state.h"
#include "io_stream_file.h"
#include "String++.h"

static const char *cmd = 0;

void
init_run_script ()
{
  extern void get_startmenu(std::string &target);  // FIXME
  extern void get_desktop(std::string &target);  // FIXME
  
  char old_path[1024];
  if ( GetEnvironmentVariable ("PATH", old_path, sizeof old_path) >= sizeof old_path )
  {
    log(LOG_PLAIN) << "error: Environment variable 'PATH' length exceeds " << sizeof old_path
                   << "; running with %WINDIR%\\system32;%WINDIR%;%WINDIR%\\wbem"
                   << endLog;

    char windir[MAX_PATH];
    if( GetEnvironmentVariable( "WINDIR", windir, sizeof windir ) >= sizeof windir ) {
      log(LOG_PLAIN) << "error: WINDIR exceeds " << sizeof windir
                     << endLog;
      return;
    }

    if( snprintf( old_path, sizeof old_path, "%s\\system32;%s;%s\\system32\\wbem", windir, windir, windir ) >= (int) sizeof old_path )
    {
      log(LOG_PLAIN) << "error: Environment variable 'PATH' length still too long"
                     << endLog;
      return;
    }
  }

  SetEnvironmentVariable ("PATH", backslash (cygpath ("/bin") + ";" + old_path).c_str());
  SetEnvironmentVariable ("OSGEO4W_ROOT", get_root_dir ().c_str());

  std::string startmenu;
  get_startmenu(startmenu);
  SetEnvironmentVariable ("OSGEO4W_STARTMENU", startmenu.c_str());

  std::string desktop;
  get_desktop(desktop);
  SetEnvironmentVariable ("OSGEO4W_DESKTOP", desktop.c_str());

  SetEnvironmentVariable ("OSGEO4W_MENU_LINKS", root_menu ? "1" : "0" );
  SetEnvironmentVariable ("OSGEO4W_DESKTOP_LINKS", root_desktop ? "1" : "0" );

  std::string path2 = get_root_dir();
  if( path2[1] == ':' )
  {
      path2[1] = path2[0];
      path2[0] = '/';
  }
  for( int i = 0; i < (int) path2.size(); i++ )
  {
      if( path2[i] == '\\' )
          path2[i] = '/';
  } 

  SetEnvironmentVariable ("OSGEO4W_ROOT_MSYS", path2.c_str() );

  cmd = "cmd.exe";
}

class OutputLog
{
public:
  OutputLog (const std::string& filename);
  ~OutputLog ();
  HANDLE handle () { return _handle; }
  BOOL isValid () { return _handle != INVALID_HANDLE_VALUE; }
  BOOL isEmpty () { return GetFileSize (_handle, NULL) == 0; }
  friend std::ostream &operator<< (std::ostream &, OutputLog &);
private:
  enum { BUFLEN = 1000 };
  HANDLE _handle;
  std::string _filename;
  void out_to(std::ostream &);
};

OutputLog::OutputLog (const std::string& filename)
  : _handle(INVALID_HANDLE_VALUE), _filename(filename)
{
  if (!_filename.size())
    return;

  SECURITY_ATTRIBUTES sa;
  memset (&sa, 0, sizeof sa);
  sa.nLength = sizeof sa;
  sa.bInheritHandle = TRUE;
  sa.lpSecurityDescriptor = NULL;

  if (mkdir_p (0, backslash (cygpath (_filename)).c_str()))
    return;

  _handle = CreateFile (backslash (cygpath (_filename)).c_str(),
      GENERIC_READ|GENERIC_WRITE, FILE_SHARE_READ|FILE_SHARE_WRITE,
      &sa, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL | FILE_FLAG_BACKUP_SEMANTICS,
      NULL);

  if (_handle == INVALID_HANDLE_VALUE)
    {
      log(LOG_PLAIN) << "error: Unable to redirect output to '" << _filename
		     << "'; using console" << endLog;
    }
}

OutputLog::~OutputLog ()
{
  if (_handle != INVALID_HANDLE_VALUE)
    CloseHandle (_handle);
  if (_filename.size() &&
      !DeleteFile(backslash (cygpath (_filename)).c_str()))
    {
      log(LOG_PLAIN) << "error: Unable to remove temporary file '" << _filename
		     << "'" << endLog;
    }
}

std::ostream &
operator<< (std::ostream &out, OutputLog &log)
{
  log.out_to(out);
  return out;
}

void
OutputLog::out_to(std::ostream &out)
{
  char buf[BUFLEN];
  DWORD num;
  FlushFileBuffers (_handle);
  SetFilePointer(_handle, 0, NULL, FILE_BEGIN);
  
  while (ReadFile(_handle, buf, BUFLEN-1, &num, NULL) && num != 0)
    {
      buf[num] = '\0';
      out << buf;
    }

  SetFilePointer(_handle, 0, NULL, FILE_END);
}

int
run (const char *cmdline)
{
  STARTUPINFO si;
  PROCESS_INFORMATION pi;
  DWORD flags = CREATE_NEW_CONSOLE;
  DWORD exitCode = 0;
  BOOL inheritHandles = FALSE;
  BOOL exitCodeValid = FALSE;

  log(LOG_PLAIN) << "running: " << cmdline << endLog;

  char tmp_pat[] = "/var/log/setup.log.runXXXXXXX";
  OutputLog file_out = std::string (mktemp (tmp_pat));

  memset (&pi, 0, sizeof pi);
  memset (&si, 0, sizeof si);
  si.cb = sizeof si;
  si.lpTitle = (char *) "OSGeo4W Setup Post-Install Script";
  si.dwFlags = STARTF_USEPOSITION;

  if (file_out.isValid ())
    {
      inheritHandles = TRUE;
      si.dwFlags |= STARTF_USESTDHANDLES;
      si.hStdInput = INVALID_HANDLE_VALUE;
      si.hStdOutput = file_out.handle ();
      si.hStdError = file_out.handle ();
      si.dwFlags |= STARTF_USESHOWWINDOW;
      si.wShowWindow = SW_HIDE;
      flags = CREATE_NO_WINDOW;
    }

  BOOL createSucceeded = CreateProcess (0, (char *)cmdline, 0, 0, inheritHandles,
					flags, 0, get_root_dir ().c_str(),
					&si, &pi);

  if (createSucceeded)
    {
      WaitForSingleObject (pi.hProcess, INFINITE);
      exitCodeValid = GetExitCodeProcess(pi.hProcess, &exitCode);
    }
  CloseHandle(pi.hProcess);
  CloseHandle(pi.hThread);

  if (!file_out.isEmpty ())
    log(LOG_BABBLE) << file_out << endLog;

  if (exitCodeValid)
    return exitCode;
  return 0-GetLastError();
}

char const *
Script::extension() const
{
  return strrchr (scriptName.c_str(), '.');
}

int
Script::run() const
{
  if (!extension())
    return -ERROR_INVALID_DATA;

  /* Bail here if the script file does not exist.  This can happen for
     example in the case of tetex-* where two or more packages contain a
     postinstall script by the same name.  When we are called the second
     time the file has already been renamed to .done, and if we don't
     return here we end up erroniously deleting this .done file.  */
  std::string windowsName = backslash (cygpath (scriptName));
  if ( !io_stream_file::exists(windowsName.c_str()) )
    {
      log(LOG_PLAIN) << "can't run " << scriptName << ": No such file"
                     << endLog;
      return -ERROR_INVALID_DATA;
    }

  int retval;
  char cmdline[MAX_PATH];

  if (cmd && (stricmp (extension(), ".bat") == 0 || stricmp (extension(), ".cmd") == 0) )
    {
      sprintf (cmdline, "%s /c \"%s\"", cmd, windowsName.c_str());
      retval = ::run (cmdline);
    }
  else
    return -ERROR_INVALID_DATA;

  if (retval)
    log(LOG_PLAIN) << "abnormal exit: exit code=" << retval << endLog;

  /* if .done file exists then delete it otherwise just ignore no file error */
  io_stream::remove ("cygfile://" + scriptName + ".done");

  /* don't rename the script as .done if it didn't run successfully */
  if (!retval)
    io_stream::move ("cygfile://" + scriptName,
                     "cygfile://" + scriptName + ".done");

  return retval;
}

int
try_run_script (const std::string& dir,
                const std::string& fname,
                const std::string& ext)
{
  if (io_stream::exists ("cygfile://" + dir + fname + ext))
    return Script (dir + fname + ext).run ();
  return NO_ERROR;
}

char const Script::ETCPostinstall[] = "/etc/postinstall/";

bool
Script::isAScript (const std::string& file)
{
    /* file may be /etc/postinstall or etc/postinstall */
    if (casecompare(file, ETCPostinstall, sizeof(ETCPostinstall)-1) &&
	casecompare(file, ETCPostinstall+1, sizeof(ETCPostinstall)-2))
      return false;
    if (file.c_str()[file.size() - 1] == '/')
      return false;
    return true;
}

Script::Script (const std::string& fileName) : scriptName (fileName)
{
  
}

std::string
Script::baseName() const
{
  std::string result = scriptName;
  result = result.substr(result.rfind('/') + 1);
  return result;
}

std::string
Script::fullName() const
{
  return scriptName;
}
