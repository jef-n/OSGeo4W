if not defined OSGEO4W_DESKTOP for /F "tokens=* USEBACKQ" %%F IN (`getspecialfolder Desktop`) do set OSGEO4W_DESKTOP=%%F
for /F "tokens=* USEBACKQ" %%F IN (`getspecialfolder Documents`) do set DOCUMENTS=%%F

call "%OSGEO4W_ROOT%\bin\@package@.bat" --postinstall
echo on

if not %OSGEO4W_MENU_LINKS%==0 if not exist "%OSGEO4W_STARTMENU%" mkdir "%OSGEO4W_STARTMENU%"
if not %OSGEO4W_DESKTOP_LINKS%==0 if not exist "%OSGEO4W_DESKTOP%" mkdir "%OSGEO4W_DESKTOP%"

if not %OSGEO4W_MENU_LINKS%==0 xxmklink "%OSGEO4W_STARTMENU%\QGIS Desktop @version@ (Nightly).lnk" "%OSGEO4W_ROOT%\bin\@package@-bin.exe" "" "%DOCUMENTS%"
if not %OSGEO4W_DESKTOP_LINKS%==0 xxmklink "%OSGEO4W_DESKTOP%\QGIS Desktop @version@ (Nightly).lnk" "%OSGEO4W_ROOT%\bin\@package@-bin.exe" "" "%DOCUMENTS%"

copy "%OSGEO4W_ROOT%\bin\@package@-bin.exe" "%OSGEO4W_ROOT%\bin\@package@-bin-grass.exe"
copy "%OSGEO4W_ROOT%\bin\@package@-bin.vars" "%OSGEO4W_ROOT%\bin\@package@-bin-grass.vars"
call "%OSGEO4W_ROOT%\bin\@package@-grass.bat" --postinstall

if not %OSGEO4W_MENU_LINKS%==0 xxmklink "%OSGEO4W_STARTMENU%\QGIS Desktop @version@ with GRASS @grassversion@ (Nightly).lnk" "%OSGEO4W_ROOT%\bin\@package@-bin-grass.exe" "" "%DOCUMENTS%"
if not %OSGEO4W_DESKTOP_LINKS%==0 xxmklink "%OSGEO4W_DESKTOP%\QGIS Desktop @version@ with GRASS @grassversion@ (Nightly).lnk" "%OSGEO4W_ROOT%\bin\@package@-bin-grass.exe" "" "%DOCUMENTS%"

if not %OSGEO4W_MENU_LINKS%==0 xxmklink "%OSGEO4W_STARTMENU%\Qt Designer with QGIS @version@ custom widgets (Nightly).lnk" "%OSGEO4W_ROOT%\bin\bgspawn.exe" "\"%OSGEO4W_ROOT%\bin\@package@-designer.bat\"" "%DOCUMENTS%" "" 1 "%OSGEO4W_ROOT%\apps\@package@\icons\QGIS.ico"
if not %OSGEO4W_DESKTOP_LINKS%==0 xxmklink "%OSGEO4W_DESKTOP%\Qt Designer with QGIS @version@ custom widgets (Nightly).lnk" "%OSGEO4W_ROOT%\bin\bgspawn.exe" "\"%OSGEO4W_ROOT%\bin\@package@-designer.bat\"" "%DOCUMENTS%" "" 1 "%OSGEO4W_ROOT%\apps\@package@\icons\QGIS.ico"

call "%OSGEO4W_ROOT%\apps\@package@\saga-refresh.bat"

set O4W_ROOT=%OSGEO4W_ROOT%
set OSGEO4W_ROOT=%OSGEO4W_ROOT:\=\\%
textreplace -std -t "%O4W_ROOT%\apps\@package@\bin\qgis.reg"
set OSGEO4W_ROOT=%O4W_ROOT%

REM Do not register extensions if release is installed
if not exist "%OSGEO4W_ROOT%\apps\qgis-ltr\bin\qgis.reg" if not exist "%OSGEO4W_ROOT%\apps\qgis\bin\qgis.reg" "%WINDIR%\regedit" /s "%OSGEO4W_ROOT%\apps\@package@\bin\qgis.reg"

call "%OSGEO4W_ROOT%\bin\o4w_env.bat"
path %PATH%;%OSGEO4W_ROOT%\apps\@package@\bin
set QGIS_PREFIX_PATH=%OSGEO4W_ROOT:\=/%/apps/@package@
"%OSGEO4W_ROOT%\apps\@package@\crssync"

del /s /q "%OSGEO4W_ROOT%\apps\@package@\python\*.pyc"
exit /b 0
