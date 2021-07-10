call "%OSGEO4W_ROOT%\bin\o4w_env.bat"
del /s /q "%OSGEO4W_ROOT%\apps\@package@\grass\*.pyc"
exit /b 0
