@echo off
call "%~dp0\o4w_env.bat"
call "%~dp0\qt6_env.bat"
call "%~dp0\gdal-dev-py-env.bat"
path %OSGEO4W_ROOT%\apps\@package@\bin;%PATH%
set QGIS_PREFIX_PATH=%OSGEO4W_ROOT:\=/%/apps/@package@
set QT_PLUGIN_PATH=%OSGEO4W_ROOT%\apps\@package@\qtplugins;%OSGEO4W_ROOT%\apps\qt6\plugins
cd %USERPROFILE%
start "Qt Designer with QGIS custom widgets" /B "%OSGEO4W_ROOT%\apps\qt6\bin\designer.exe" %*
