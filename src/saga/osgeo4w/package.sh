export P=saga
export V=7.8.2
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="wxwidgets-devel libharu-devel gdal-devel proj-devel libpq-devel curl-devel libpng-devel libtiff-devel libjpeg-turbo-devel zlib-devel expat-devel pdal-devel"


source ../../../scripts/build-helpers

startlog

M=${V%%.*}
p=${P%$M}

[ -f $p-$V.zip ] || wget -O $p-$V.zip "https://sourceforge.net/projects/$p-gis/files/${p^^}%20-%20$M/${p^^}%20-%20$V/saga-${V}_src.zip/download"
[ -d ../saga-${V}_src ] || {
	unzip -q -d .. $p-$V.zip
	rm -f ../saga-${V}_src/patched
}
[ -f ../saga-${V}_src/patched ] || {
	patch -d ../saga-${V}_src -p1 --dry-run <patch
	patch -d ../saga-${V}_src -p1 <patch
	touch ../saga-${V}_src/patched
}

(
	set -e

	fetchenv osgeo4w/bin/o4w_env.bat
	vs2019env

	set -x

	export WXWIN=$(cygpath -am osgeo4w)
	export LIB="$(cygpath -am osgeo4w/lib);$LIB"
	export INCLUDE="$(cygpath -am osgeo4w/lib/vc_x64_dll/mswu);$(cygpath -am osgeo4w/include);$INCLUDE"

	cd ../saga-${V}_src/saga-gis/src

	rm -f $OSGEO4W_PWD/build.log

	devenv saga.vc14.sln /UseEnv /Build "Release|x64" /Out $(cygpath -aw $OSGEO4W_PWD/build.log) ||
	devenv saga.vc14.sln /UseEnv /Build "Release|x64" /Out $(cygpath -aw $OSGEO4W_PWD/build.log) ||
	{ cat $OSGEO4W_PWD/build.log; false; }

	cd dev_tools
	devenv dev_tools.vc14.sln /UseEnv /Build "Release|x64" /Out $(cygpath -aw $OSGEO4W_PWD/build-dev.log) ||
	{ cat $OSGEO4W_PWD/build-dev.log; false; }
)

mkdir -p install/{bin,etc/{postinstall,preremove},apps/$P}

cat <<EOF >install/bin/${P}_gui.bat
call "%~dp0\\o4w_env.bat"
"%OSGEO4W_ROOT%\\apps\\$P\\saga_gui.exe"
EOF

cat <<EOF >install/etc/postinstall/$P.bat
if not defined OSGEO4W_DESKTOP for /F "tokens=* USEBACKQ" %%F IN (\`getspecialfolder Desktop\`) do set OSGEO4W_DESKTOP=%%F
for /F "tokens=* USEBACKQ" %%F IN (\`getspecialfolder Documents\`) do set DOCUMENTS=%%F

if not %OSGEO4W_MENU_LINKS%==0 if not exist "%OSGEO4W_STARTMENU%" mkdir "%OSGEO4W_STARTMENU%"
if not %OSGEO4W_DESKTOP_LINKS%==0 if not exist "%OSGEO4W_DESKTOP%" mkdir "%OSGEO4W_DESKTOP%"

if not %OSGEO4W_MENU_LINKS%==0 xxmklink "%OSGEO4W_STARTMENU%\\SAGA GIS $V.lnk" "%OSGEO4W_ROOT%\\bin\\bgspawn.exe" "\\"%OSGEO4W_ROOT%\\bin\\saga_gui.bat\\"" "%DOCUMENTS%" "" 1 "%OSGEO4W_ROOT%\\apps\\$P\\saga_gui.exe"
if not %OSGEO4W_DESKTOP_LINKS%==0 xxmklink "%OSGEO4W_DESKTOP%\\SAGA GIS $V.lnk" "%OSGEO4W_ROOT%\\bin\\bgspawn.exe" "\\"%OSGEO4W_ROOT%\\bin\\saga_gui.bat\\"" "%DOCUMENTS%" "" 1 "%OSGEO4W_ROOT%\\apps\\$P\\saga_gui.exe"

for /f "tokens=* usebackq" %%f in (\`dir /s /b "%OSGEO4W_ROOT%\\apps\\saga-refresh.bat"\`) do call "%%f"
EOF

cat <<EOF >install/etc/preremove/$P.bat
if not defined OSGEO4W_DESKTOP for /F "tokens=* USEBACKQ" %%F IN (\`getspecialfolder Desktop\`) do set OSGEO4W_DESKTOP=%%F
del "%OSGEO4W_STARTMENU%\\SAGA GIS $V.lnk"
del "%OSGEO4W_DESKTOP%\\SAGA GIS $V.lnk"

del "%OSGEO4W_ROOT%\\apps\\saga\\tools\\dev_tools.dll"
for /f "tokens=* usebackq" %%f in (\`dir /s /b "%OSGEO4W_ROOT%\\apps\\saga-refresh.bat"\`) do call "%%f"
EOF

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R

cat <<EOF >$R/setup.hint
sdesc: "SAGA (System for Automated Geographical Analyses)"
ldesc: "SAGA (System for Automated Geographical Analyses)"
requires: wxwidgets libharu $RUNTIMEDEPENDS libpq curl pdal-libs
maintainer: $MAINTAINER
category: Desktop
EOF

cd ..

tar -cjf $R/$P-$V-$B.tar.bz2 \
	--xform "s,^osgeo4w/install/,," \
	--xform "s,^saga-${V}_src/saga-gis/bin/saga_vc_x64/,apps/$P/," \
	-T <(find osgeo4w/install saga-${V}_src/saga-gis/bin/saga_vc_x64 -type f)

tar -cjf $R/$P-$V-$B-src.tar.bz2 \
	osgeo4w/package.sh \
	osgeo4w/patch

cp saga-${V}_src/saga-gis/COPYING $R/$P-$V-$B.txt

endlog
