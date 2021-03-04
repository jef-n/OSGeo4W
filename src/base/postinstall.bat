if not %OSGEO4W_MENU_LINKS%==0 mkdir "%OSGEO4W_STARTMENU%"
if not %OSGEO4W_MENU_LINKS%==0 xxmklink "%OSGEO4W_STARTMENU%\OSGeo4W Shell.lnk" "%OSGEO4W_ROOT%\OSGeo4W.bat" " " \ "OSGeo for Windows command shell" 1 "%OSGEO4W_ROOT%\OSGeo4W.ico"
if not %OSGEO4W_DESKTOP_LINKS%==0 mkdir "%OSGEO4W_DESKTOP%"
if not %OSGEO4W_DESKTOP_LINKS%==0 xxmklink "%OSGEO4W_DESKTOP%\OSGeo4W Shell.lnk" "%OSGEO4W_ROOT%\OSGeo4W.bat" " " \ "OSGeo for Windows command shell" 1 "%OSGEO4W_ROOT%\OSGeo4W.ico"
