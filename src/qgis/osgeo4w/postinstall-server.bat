call "%OSGEO4W_ROOT%\bin\o4w_env.bat"
textreplace -std ^
	-map @windir@ "%WINDIR%" ^
	-map @temp@ "%TEMP%" ^
	-t httpd.d\httpd_@package@.conf
del httpd.d\httpd_@package@.conf.tmpl
