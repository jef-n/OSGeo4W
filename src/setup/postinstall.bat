nircmd shortcut "%OSGEO4W_ROOT%\bin\nircmd.exe" "%OSGEO4W_STARTMENU%" "Setup" "exec hide ~q%OSGEO4W_ROOT%\bin\setup.bat~q" "%OSGEO4W_ROOT%\OSGeo4W.ico"
textreplace -std -t bin/setup.bat
textreplace -std -t bin/setup-test.bat
