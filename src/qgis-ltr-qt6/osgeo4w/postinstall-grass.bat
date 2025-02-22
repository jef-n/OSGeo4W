call "%OSGEO4W_ROOT%\bin\o4w_env.bat"
call "%OSGEO4W_ROOT%\bin\qt6_env.bat"
set APPNAME=QGIS Desktop @version@ (Qt6)
for %%i in ("%OSGEO4W_STARTMENU%") do set QGIS_WIN_APP_NAME=%%~ni\%APPNAME%
call "%OSGEO4W_ROOT%\bin\@package@.bat" --postinstall
del /s /q "%OSGEO4W_ROOT%\apps\@package@\grass\*.pyc"
exit /b 0
