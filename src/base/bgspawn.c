/******************************************************************************
 *
 * Project:  OSGeo4W
 * Purpose:  Start process in background
 * Author:   Jürgen E. Fischer, jef@norbit.de
 *
 ******************************************************************************
 * Copyright (c) 2020, Jürgen E. Fischer, norBIT GmbH
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 ****************************************************************************/

#include <windows.h>
#include <tchar.h>

int APIENTRY wWinMain(_In_ HINSTANCE hInstance, _In_opt_ HINSTANCE hPrevInstance, _In_ LPWSTR lpCmdLine, _In_ int nCmdShow)
{
  int argc = 0;
  LPWSTR *argv = CommandLineToArgvW(lpCmdLine, &argc);
  if(argc < 1)
    return 1;

  STARTUPINFOW si;
  ZeroMemory(&si, sizeof(STARTUPINFOW));
  si.cb          = sizeof(STARTUPINFOW);
  si.dwFlags    |= STARTF_USESHOWWINDOW;
  si.wShowWindow = SW_HIDE;

  PROCESS_INFORMATION pi;
  ZeroMemory(&pi, sizeof(PROCESS_INFORMATION));
  si.cb = sizeof(PROCESS_INFORMATION);

  OutputDebugStringW(lpCmdLine);

  BOOL ok = CreateProcessW(NULL, lpCmdLine, NULL, NULL, FALSE, CREATE_NO_WINDOW, NULL, NULL, &si, &pi);
  CloseHandle(&pi);
  if(ok)
    OutputDebugStringW(L"ok");
  else
  {
    LPWSTR lpMsgBuf;
    FormatMessageW( FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM |  FORMAT_MESSAGE_IGNORE_INSERTS, NULL, GetLastError(), MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), (LPWSTR) &lpMsgBuf, 0, NULL );
    lpMsgBuf[wcslen(lpMsgBuf)-1]=0;

    OutputDebugStringW(lpMsgBuf);

    LocalFree(lpMsgBuf);
  }
  return ok ? 0 : 2;
}
