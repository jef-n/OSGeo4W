del "%OSGEO4W_STARTMENU%\QGIS Desktop @version@ (Nightly).lnk"
del "%OSGEO4W_STARTMENU%\QGIS Desktop @version@ with GRASS @grassversion@ (Nightly).lnk"
del "%OSGEO4W_STARTMENU%\Qt Designer with QGIS @version@ custom widgets (Nightly).lnk"
rmdir "%OSGEO4W_STARTMENU%"
del "%OSGEO4W_DESKTOP%\QGIS Desktop @version@ (Nightly).lnk"
del "%OSGEO4W_DESKTOP%\Qt Designer with QGIS @version@ custom widgets (Nightly).lnk"
del "%OSGEO4W_DESKTOP%\QGIS Desktop @version@ with GRASS @grassversion@ (Nightly).lnk"
rmdir "%OSGEO4W_DESKTOP%"
del "%OSGEO4W_ROOT%\bin\@package@.bat"
del "%OSGEO4W_ROOT%\bin\@package@-bin.vars"
del "%OSGEO4W_ROOT%\bin\@package@-bin.env"
del "%OSGEO4W_ROOT%\bin\@package@-grass.bat"
del "%OSGEO4W_ROOT%\bin\@package@-bin-grass.exe"
del "%OSGEO4W_ROOT%\bin\@package@-bin-grass.env"
del "%OSGEO4W_ROOT%\bin\@package@-bin-grass.vars"
del "%OSGEO4W_ROOT%\bin\@package@-designer.bat"
del "%OSGEO4W_ROOT%\apps\@package@\python\qgis\qgisconfig.py"
del "%OSGEO4W_ROOT%\apps\@package@\bin\qgis.reg"
del /s /q "%OSGEO4W_ROOT%\apps\@package@\python\*.pyc"
rmdir /s /q "%OSGEO4W_ROOT%\apps\@package@\python\plugins\processing\algs\saga\description"
rmdir /s /q "%OSGEO4W_ROOT%\apps\@package@\python\plugins\processing\algs\saga\description.dist"
del "%OSGEO4W_ROOT%\apps\@package@\python\plugins\processing\algs\saga\SagaNameDecorator.py"
del "%OSGEO4W_ROOT%\apps\@package@\python\plugins\processing\algs\saga\SagaNameDecorator.py.dist"