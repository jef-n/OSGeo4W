if not defined OSGEO4W_DESKTOP for /F "tokens=* USEBACKQ" %%F IN (`getspecialfolder Desktop`) do set OSGEO4W_DESKTOP=%%F
for /F "tokens=* USEBACKQ" %%F IN (`getspecialfolder Documents`) do set DOCUMENTS=%%F

call "%OSGEO4W_ROOT%\bin\@package@.bat" --postinstall
echo on

if not %OSGEO4W_MENU_LINKS%==0 if not exist "%OSGEO4W_STARTMENU%" mkdir "%OSGEO4W_STARTMENU%"
if not %OSGEO4W_DESKTOP_LINKS%==0 if not exist "%OSGEO4W_DESKTOP%" mkdir "%OSGEO4W_DESKTOP%"

if not %OSGEO4W_MENU_LINKS%==0 xxmklink "%OSGEO4W_STARTMENU%\QGIS Desktop @version@.lnk" "%OSGEO4W_ROOT%\bin\@package@-bin.exe" "" "%DOCUMENTS%"
if not %OSGEO4W_DESKTOP_LINKS%==0 xxmklink "%OSGEO4W_DESKTOP%\QGIS Desktop @version@.lnk" "%OSGEO4W_ROOT%\bin\@package@-bin.exe" "" "%DOCUMENTS%"

if not %OSGEO4W_MENU_LINKS%==0 xxmklink "%OSGEO4W_STARTMENU%\Qt Designer with QGIS @version@ custom widgets.lnk" "%OSGEO4W_ROOT%\bin\bgspawn.exe" "\"%OSGEO4W_ROOT%\bin\@package@-designer.bat\"" "%DOCUMENTS%" "" 1 "%OSGEO4W_ROOT%\apps\@package@\icons\QGIS.ico"
if not %OSGEO4W_DESKTOP_LINKS%==0 xxmklink "%OSGEO4W_DESKTOP%\Qt Designer with QGIS @version@ custom widgets.lnk" "%OSGEO4W_ROOT%\bin\bgspawn.exe" "\"%OSGEO4W_ROOT%\bin\@package@-designer.bat\"" "%DOCUMENTS%" "" 1 "%OSGEO4W_ROOT%\apps\@package@\icons\QGIS.ico"

call "%OSGEO4W_ROOT%\apps\@package@\saga-refresh.bat"

set O4W_ROOT=%OSGEO4W_ROOT%
set OSGEO4W_ROOT=%OSGEO4W_ROOT:\=\\%
textreplace -std -t "%O4W_ROOT%\apps\@package@\bin\qgis.reg"
set OSGEO4W_ROOT=%O4W_ROOT%

REM Do not register extensions if long-term release is installed
if not exist "%OSGEO4W_ROOT%\apps\qgis-ltr\bin\qgis.reg" "%WINDIR%\regedit" /s "%OSGEO4W_ROOT%\apps\@package@\bin\qgis.reg"
del /s /q "%OSGEO4W_ROOT%\apps\@package@\python\*.pyc"
exit /b 0
