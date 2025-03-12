export P=apache
export V=2.4.63
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none
export PACKAGES=apache

export SERVICENAME="Apache OSGeo4W Web Server"

source ../../../scripts/build-helpers

startlog

v=${V%.*}
v=${v/./}
z=httpd-$V-250207-win64-VS17.zip

[ -f $z ] || curl -L -A Mozilla/5.0 -O https://www.apachelounge.com/download/VS17/binaries/$z
unzip -o $z "Apache$v/*"

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R

cat <<EOF >$R/setup.hint
sdesc: "Apache Webserver"
ldesc: "Apache Webserver (apachelounge binaries)"
maintainer: $MAINTAINER
category: Web
requires: msvcrt2019
EOF

	cat <<EOF >postinstall.bat
REM set paths
if not defined APACHE_PORT set APACHE_PORT=80
if not defined APACHE_HOSTNAME set APACHE_HOSTNAME=%computername%

textreplace -std ^
	-map @o4wroot@ %OSGEO4W_ROOT:\=/% ^
	-map @apache_hostname@ %APACHE_HOSTNAME% ^
	-map @apache_port_number@ %APACHE_PORT% ^
	-t apps/apache/conf/httpd.conf

REM create start menu links
if not %OSGEO4W_MENU_LINKS%==0 (
	if not exist "%OSGEO4W_STARTMENU%\\Apache" mkdir "%OSGEO4W_STARTMENU%\\Apache"
	xxmklink "%OSGEO4W_STARTMENU%\\Apache\\Install Apache Web Service.lnk" "%OSGEO4W_ROOT%\\apps\\apache\\bin\\httpd.exe" "-k install -n ""$SERVICENAME"""
	xxmklink "%OSGEO4W_STARTMENU%\\Apache\\Uninstall Apache Web Service.lnk" "%OSGEO4W_ROOT%\\apps\\apache\\bin\\httpd.exe" "-k uninstall -n ""$SERVICENAME"""
	xxmklink "%OSGEO4W_STARTMENU%\\Apache\\Start Apache Web Service.lnk" "%OSGEO4W_ROOT%\\apps\\apache\\bin\\httpd.exe" "-k install -n ""$SERVICENAME"""
	xxmklink "%OSGEO4W_STARTMENU%\\Apache\\Stop Apache Web Service.lnk" "%OSGEO4W_ROOT%\\apps\\apache\\bin\\httpd.exe" "-k start -n ""$SERVICENAME"""
	xxmklink "%OSGEO4W_STARTMENU%\\Apache\\Install Apache Web Service.lnk" "%OSGEO4W_ROOT%\\apps\\apache\\bin\\httpd.exe" "-k stop -n ""$SERVICENAME"""
	xxmklink "%OSGEO4W_STARTMENU%\\Apache\\Apache Monitor.lnk" "%OSGEO4W_ROOT%\\apps\\apache\\bin\\ApacheMonitor.exe"
)

REM create desktop links
if not %OSGEO4W_DESKTOP_LINKS%==0 (
	if not exist "%OSGEO4W_DESKTOP%\\Apache" mkdir "%OSGEO4W_DESKTOP%\\Apache"
	xxmklink "%OSGEO4W_DESKTOP%\\Apache\\Install Apache Web Service.lnk" "%OSGEO4W_ROOT%\\apps\\apache\\bin\\httpd.exe" "-k install -n ""$SERVICENAME"""
	xxmklink "%OSGEO4W_DESKTOP%\\Apache\\Uninstall Apache Web Service.lnk" "%OSGEO4W_ROOT%\\apps\\apache\\bin\\httpd.exe" "-k uninstall -n ""$SERVICENAME"""
	xxmklink "%OSGEO4W_DESKTOP%\\Apache\\Start Apache Web Service.lnk" "%OSGEO4W_ROOT%\\apps\\apache\\bin\\httpd.exe" "-k install -n ""$SERVICENAME"""
	xxmklink "%OSGEO4W_DESKTOP%\\Apache\\Stop Apache Web Service.lnk" "%OSGEO4W_ROOT%\\apps\\apache\\bin\\httpd.exe" "-k start -n ""$SERVICENAME"""
	xxmklink "%OSGEO4W_DESKTOP%\\Apache\\Install Apache Web Service.lnk" "%OSGEO4W_ROOT%\\apps\\apache\\bin\\httpd.exe" "-k stop -n ""$SERVICENAME"""
	xxmklink "%OSGEO4W_DESKTOP%\\Apache\\Apache Monitor.lnk" "%OSGEO4W_ROOT%\\apps\\apache\\bin\\ApacheMonitor.exe"
)

REM install and start the apache service
call apache-install.bat
exit /b 0
EOF

	cat <<EOF >preremove.bat
REM "%OSGEO4W_ROOT%\\bin\\apache-uninstall.bat"

del "%OSGEO4W_STARTMENU%\\Apache\\Install Apache Web Service.lnk"
del "%OSGEO4W_STARTMENU%\\Apache\\Uninstall Apache Web Service.lnk"
del "%OSGEO4W_STARTMENU%\\Apache\\Start Apache Web Service.lnk"
del "%OSGEO4W_STARTMENU%\\Apache\\Stop Apache Web Service.lnk"
del "%OSGEO4W_STARTMENU%\\Apache\\Apache Monitor.lnk"
rd "%OSGEO4W_STARTMENU%\\Apache"

del "%OSGEO4W_DESKTOP%\\Apache\\Install Apache Web Service.lnk"
del "%OSGEO4W_DESKTOP%\\Apache\\Uninstall Apache Web Service.lnk"
del "%OSGEO4W_DESKTOP%\\Apache\\Start Apache Web Service.lnk"
del "%OSGEO4W_DESKTOP%\\Apache\\Stop Apache Web Service.lnk"
del "%OSGEO4W_DESKTOP%\\Apache\\Apache Monitor.lnk"
rd "%OSGEO4W_DESKTOP%\\Apache"

del "%OSGEO4W_ROOT\\apps\\apache\\conf\\httpd.conf"

REM stop and uninstall the apache service
call apache-uninstall.bat
exit /b 0
EOF

	cat <<EOF >apache-install.bat
@echo off

REM This installs and starts the apache service
%OSGEO4W_ROOT%\\apps\\apache\\bin\\httpd -k install -n "$SERVICENAME"
%OSGEO4W_ROOT%\\apps\\apache\\bin\\httpd -k start -n "$SERVICENAME"
EOF

	cat <<EOF >apache-uninstall.bat
@echo off

REM This stops and uninstalls apache service
%OSGEO4W_ROOT%\\apps\\apache\\bin\\httpd -k stop -n "$SERVICENAME"
%OSGEO4W_ROOT%\\apps\\apache\\bin\\httpd -k uninstall -n "$SERVICENAME"
EOF

	cat <<EOF >apache-restart.bat
@echo off

REM This restarts the apache service
%OSGEO4W_ROOT%\\apps\\apache\\bin\\httpd -k restart -n "$SERVICENAME"
EOF


sed \
	-e 's#^Listen 80#Listen ${SRVPORT}\nServerName ${SRVHOST}#' \
	-e 's#^Define SRVROOT "c:/Apache'$v'"#Define SRVROOT "@o4wroot@/apps/apache"\nDefine SRVPORT @apache_port_number@\nDefine SRVHOST "@apache_hostname@"\n#' \
	-e '$a\\n# parse OSGeo4W apache conf files\nIncludeOptional "@o4wroot@/httpd.d/httpd_*.conf"' \
	Apache$v/conf/httpd.conf >httpd.conf.tmpl

cp Apache$v/LICENSE.txt $R/$P-$V-$B.txt

tar -cjf $R/$P-$V-$B.tar.bz2 \
	--xform s,^Apache$v,apps/apache, \
	--xform s,^postinstall.bat,etc/postinstall/apache.bat, \
	--xform s,^preremove.bat,etc/preremove/apache.bat, \
	--xform s,^apache-install.bat,bin/apache-install.bat, \
	--xform s,^apache-uninstall.bat,bin/apache-uninstall.bat, \
	--xform s,^apache-restart.bat,bin/apache-restart.bat, \
	--xform s,^httpd.conf.tmpl,apps/apache/conf/httpd.conf.tmpl, \
	--xform s,^README.txt,httpd.d/README.txt, \
	--exclude Apache$v/conf/httpd.conf \
	--exclude Apache$v/logs/install.log \
	--exclude Apache$v/conf/original \
	httpd.conf.tmpl \
	postinstall.bat \
	preremove.bat \
	apache-install.bat \
	apache-uninstall.bat \
	apache-restart.bat \
	Apache$v

tar -cjf $R/$P-$V-$B-src.tar.bz2 \
	-C .. \
	osgeo4w/package.sh

rm -r Apache$v

endlog
