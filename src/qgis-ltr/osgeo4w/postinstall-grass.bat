call "%OSGEO4W_ROOT%\bin\o4w_env.bat"

if not defined OSGEO4W_DESKTOP for /F "tokens=* USEBACKQ" %%F IN (`getspecialfolder Desktop`) do set OSGEO4W_DESKTOP=%%F
for /F "tokens=* USEBACKQ" %%F IN (`getspecialfolder Documents`) do set DOCUMENTS=%%F

call "%OSGEO4W_ROOT%\bin\@package@.bat" --postinstall
echo on

del /s /q "%OSGEO4W_ROOT%\apps\@package@\grass\*.pyc"
exit /b 0
