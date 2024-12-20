export P=saga
export V=9.7.1
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="wxwidgets-devel libharu-devel gdal-devel proj-devel libpq-devel curl-devel libpng-devel libtiff-devel libjpeg-turbo-devel zlib-devel expat-devel pdal-devel"
export PACKAGES="saga"

source ../../../scripts/build-helpers

startlog

M=${V%%.*}
p=${P%$M}

[ -f $p-$V.zip ] || wget -O $p-$V.zip "https://sourceforge.net/projects/$p-gis/files/${p^^}%20-%20$M/${p^^}%20-%20$V/saga-${V}_src.zip/download"
[ -d ../$P-$V ] || {
	unzip -q -d .. $P-$V.zip
	rm -f ../$P-$V/patched
}
[ -f ../saga-$V/patched ] || {
	patch -d ../$P-$V -p1 --dry-run <patch
	patch -d ../$P-$V -p1 <patch >../saga-$V/patched
}

(
	set -e

	fetchenv osgeo4w/bin/o4w_env.bat
	vsenv
	cmakeenv
	ninjaenv

	set -x

	export WXWIN=$(cygpath -am osgeo4w)
	export LIB="$(cygpath -am osgeo4w/lib);$LIB"
	export INCLUDE="$(cygpath -am osgeo4w/lib/vc_x64_dll/mswu);$(cygpath -am osgeo4w/include);$INCLUDE"

	mkdir -p build install
	cd build

	cmake -G Ninja \
		-D CMAKE_BUILD_TYPE=Release \
		-D CURL_LIBRARIES=$(cygpath -am ../osgeo4w/lib/libcurl.lib) \
		-D PDAL_UTIL_LIBRARY=$(cygpath -am ../osgeo4w/lib/pdalcpp.lib) \
		-D wxWidgets_CONFIGURATION=mswu \
		-D wxWidgets_ROOT_DIR=$(cygpath -am ../osgeo4w) \
		-D wxWidgets_LIB_DIR=$(cygpath -am ../osgeo4w/lib/vc_x64_dll) \
		-D CMAKE_INSTALL_PREFIX=$(cygpath -am ../install/apps/$P) \
		../../$P-$V/saga-gis

	ninja
	ninja install
	cmakefix ../install
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

if not %OSGEO4W_MENU_LINKS%==0 xxmklink "%OSGEO4W_STARTMENU%\\SAGA GIS $V.lnk" "%OSGEO4W_ROOT%\\bin\\bgspawn.exe" "\\"%OSGEO4W_ROOT%\\bin\\${P}_gui.bat\\"" "%DOCUMENTS%" "" 1 "%OSGEO4W_ROOT%\\apps\\$P\\saga_gui.exe"
if not %OSGEO4W_DESKTOP_LINKS%==0 xxmklink "%OSGEO4W_DESKTOP%\\SAGA GIS $V.lnk" "%OSGEO4W_ROOT%\\bin\\bgspawn.exe" "\\"%OSGEO4W_ROOT%\\bin\\${P}_gui.bat\\"" "%DOCUMENTS%" "" 1 "%OSGEO4W_ROOT%\\apps\\$P\\saga_gui.exe"

del %OSGEO4W_ROOT%\\saga_gui.ini
EOF

cat <<EOF >install/etc/preremove/$P.bat
if not defined OSGEO4W_DESKTOP for /F "tokens=* USEBACKQ" %%F IN (\`getspecialfolder Desktop\`) do set OSGEO4W_DESKTOP=%%F
del "%OSGEO4W_STARTMENU%\\SAGA GIS $V.lnk"
del "%OSGEO4W_DESKTOP%\\SAGA GIS $V.lnk"
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

tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	--xform "s,./,," \
	.

mkdir -p $OSGEO4W_REP/x86_64/release/saga9

cat <<EOF >$OSGEO4W_REP/x86_64/release/saga9/setup.hint
sdesc: "SAGA (System for Automated Geographical Analyses; transitional package)"
ldesc: "SAGA (System for Automated Geographical Analyses; transitional package)"
category: _obsolete
requires: saga
maintainer: $MAINTAINER
external-source: saga
EOF

d=$(mktemp -d)
tar -C $d -cjf $OSGEO4W_REP/x86_64/release/saga9/saga9-99-1.tar.bz2 .
rmdir $d

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh osgeo4w/patch

cp ../saga-$V/saga-gis/src/gpl.txt $R/$P-$V-$B.txt

endlog
