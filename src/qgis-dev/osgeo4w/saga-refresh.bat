setlocal enabledelayedexpansion

set SAGA_VER=@sagadef@

if exist "%OSGEO4W_ROOT%\apps\saga\tools\dev_tools.dll" (
	if not exist "%OSGEO4W_ROOT%\apps\@package@\python\plugins\sagaprovider\description.dist" (
		ren "%OSGEO4W_ROOT%\apps\@package@\python\plugins\sagaprovider\description" description.dist
		ren "%OSGEO4W_ROOT%\apps\@package@\python\plugins\sagaprovider\SagaNameDecorator.py" SagaNameDecorator.py.dist
	)

	"%OSGEO4W_ROOT%\apps\saga\saga_cmd" dev_tools 7 -DIRECTORY "%OSGEO4W_ROOT%\apps\@package@\python\plugins\sagaprovider" -CLEAR 0
	for /f "tokens=3 usebackq" %%a in (`"%OSGEO4W_ROOT%\apps\saga\saga_cmd" -v`) do set v=%%a
	for /f "tokens=1,2 delims=." %%a in ("!v!") do set SAGA_VER='%%a.%%b.'
	del "%OSGEO4W_ROOT%\apps\@package@\python\plugins\sagaprovider\readme.txt"
) else if exist "%OSGEO4W_ROOT%\apps\@package@\python\plugins\sagaprovider\description.dist" (
	rmdir /s /q "%OSGEO4W_ROOT%\apps\@package@\python\plugins\sagaprovider\description"
	del "%OSGEO4W_ROOT%\apps\@package@\python\plugins\sagaprovider\SagaNameDecorator.py"

	ren "%OSGEO4W_ROOT%\apps\@package@\python\plugins\sagaprovider\description.dist" description
	ren "%OSGEO4W_ROOT%\apps\@package@\python\plugins\sagaprovider\SagaNameDecorator.py.dist" SagaNameDecorator.py.dist
)

textreplace ^
	-sf "%OSGEO4W_ROOT%\apps\@package@\python\plugins\sagaprovider\SagaAlgorithmProvider.py.tmpl" ^
	-df "%OSGEO4W_ROOT%\apps\@package@\python\plugins\sagaprovider\SagaAlgorithmProvider.py" ^
	-map @saga@ "%SAGA_VER%"

endlocal
