export P=pgmodeler
export V=1.2.0
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="qt6-devel libxml2-devel libpq-devel"
export PACKAGES=pgmodeler

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget -O $P-$V.tar.gz https://github.com/$P/$P/archive/refs/tags/v$V.tar.gz
[ -d ../$P-$V ] || tar -C .. -xzf $P-$V.tar.gz
[ -f ../$P-$V/patched ] || {
	patch -d ../$P-$V -p1 --dry-run <patch
	patch -d ../$P-$V -p1 <patch >../$P-$V/patched
}

(
	cd $OSGEO4W_PWD

	fetchenv osgeo4w/bin/o4w_env.bat
	fetchenv osgeo4w/bin/qt6_env.bat

	PATH=$PATH:$(cygpath --sysdir)/WindowsPowerShell/v1.0

	vsenv

	mkdir -p build install

	cd build

	[ Makefile -nt ../../$P-$V/pgmodeler.pro ] ||
	qmake \
		CONFIG+=release \
		DEFINES+=__PRETTY_FUNCTION__=__FUNCTION__ \
		PREFIX=$(cygpath -am ../install/apps/$P) \
		PGSQL_LIB=$(cygpath -am ../osgeo4w/lib/libpq.lib) \
		PGSQL_INC=$(cygpath -am ../osgeo4w/include) \
		XML_LIB=$(cygpath -am ../osgeo4w/lib/libxml2.lib) \
		XML_INC=$(cygpath -am ../osgeo4w/include/libxml2) \
		NO_UPDATE_CHECK=1 \
		../../$P-$V/pgmodeler.pro

	[ -x jom.exe ] || {
		wget -q http://download.qt.io/official_releases/jom/jom.zip
		unzip jom.zip jom.exe
		chmod a+rx jom.exe
	}

	./jom
	./jom install
)

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R

cat <<EOF >$R/setup.hint
sdesc: "PostgreSQL Database Modeler"
ldesc: "PostgreSQL Database Modeler"
maintainer: $MAINTAINER
category: Desktop
requires: msvcrt2019 base qt6-libs libpq libxml2
EOF

mkdir -p install/{bin,etc/{postinstall,preremove}}

cat <<EOF >install/bin/$P.bat
call "%~dp0\o4w_env.bat"
call "%~dp0\qt6_env.bat"
set PGMODELER_SCHEMAS_DIR=%OSGEO4W_ROOT%\\apps\\pgmodeler\schemas
set PGMODELER_CONF_DIR=%OSGEO4W_ROOT%\\apps\\pgmodeler\\conf
set PGMODELER_SAMPLES_DIR=%OSGEO4W_ROOT%\\apps\\pgmodeler\\samples
set PGMODELER_TMPL_CONF_DIR=%OSGEO4W_ROOT%\\apps\\pgmodeler\\tmpl
set PGMODELER_TEMP_DIR=%TEMP%
set PGMODELER_CH_PATH=%OSGEO4W_ROOT%\\apps\pgmodeler\\pgmodeler-ch.exe
set PGMODELER_CLI_PATH=%OSGEO4W_ROOT%\\apps\pgmodeler\\pgmodeler-cli.exe
set PGMODELER_SE_PATH=%OSGEO4W_ROOT%\\apps\pgmodeler\\pgmodeler-se.exe
set PGMODELER_PATH=%OSGEO4W_ROOT%\\apps\\pgmodeler\\pgmodeler.exe
start "PostgreSQL Database Modeler" /B "%OSGEO4W_ROOT%"\\apps\\$P\\$P.exe %*
EOF

cat <<EOF >install/etc/postinstall/$P.bat
for %%i in ("%OSGEO4W_ROOT%") do set O4W_ROOT=%%~fsi

if not %OSGEO4W_MENU_LINKS%==0 if not exist "%OSGEO4W_STARTMENU%" mkdir "%OSGEO4W_STARTMENU%"
if not %OSGEO4W_DESKTOP_LINKS%==0 if not exist "%OSGEO4W_DESKTOP%" mkdir "%OSGEO4W_DESKTOP%"

if not %OSGEO4W_MENU_LINKS%==0 xxmklink "%OSGEO4W_STARTMENU%\\PostgreSQL Database Modeler.lnk" "%O4W_ROOT%\\bin\\bgspawn.exe" "%O4W_ROOT%\\bin\\$P.bat"
if not %OSGEO4W_DESKTOP_LINKS%==0 xxmklink "%OSGEO4W_DESKTOP%\\PostgreSQL Database Modeler.lnk" "%O4W_ROOT%\\bin\\bgspawn.exe" "%O4W_ROOT%\\bin\\$P.bat"
EOF

cat <<EOF >install/etc/preremove/$P.bat
del "%OSGEO4W_STARTMENU%\\PostgreSQL Database Modeler.lnk"
del "%OSGEO4W_DESKTOP%\\PostgreSQL Database Modeler.lnk"
EOF

tar -cvjf $R/$P-$V-$B.tar.bz2 \
	--xform "s,^install/,," \
	install

cp ../$P-$V/LICENSE $R/$P-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 \
	osgeo4w/package.sh

endlog
