export P=gpsbabel
export V=1.8.0
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="qt5-devel zlib-devel expat-devel gdal-devel"

source ../../../scripts/build-helpers

startlog

[ -f ${P}_${V//./_}.tar.gz ] || wget https://github.com/$P/$P/archive/${P}_${V//./_}.tar.gz
[ -f ../$P-$V/CMakeLists.txt ] || tar -C .. -xzf ${P}_${V//./_}.tar.gz --xform "s,${P}-${P}_${V//_/.},$P-$V,"
[ -f ../$P-$V/CMakeLists.txt ]

(
	fetchenv osgeo4w/bin/o4w_env.bat
	vs2019env
	cmakeenv
	ninjaenv

	export LIB="$(cygpath -am ../osgeo4w/lib);$LIB"
	export INCLUDE="$(cygpath -am ../osgeo4w/include);$INCLUDE"

	mkdir -p build install
	cd build

	cmake -G Ninja \
		-D CMAKE_BUILD_TYPE=Release \
		-D CMAKE_INSTALL_PREFIX=$(cygpath -am ../install) \
		-D GPSBABEL_MAPPREVIEW=OFF \
		../../$P-$V
	cmake --build .
)

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-gui

cat <<EOF >$R/setup.hint
sdesc: "GPS file conversion plus transfer to/from GPS units"
ldesc: "GPS file conversion plus transfer to/from GPS units"
maintainer: $MAINTAINER
category: Commandline_Utilities
requires: msvcrt2019 expat zlib $RUNTIME_DEPENDS
EOF

cat <<EOF >$R/$P-gui/setup.hint
sdesc: "GPSBabel GUI Frontend"
ldesc: "GPSBabel GUI Frontend"
maintainer: $MAINTAINER
category: Desktop
requires: base msvcrt2019 qt5-libs $P
external-source: $P
EOF

cat <<EOF >gui.bat
call "%~dp0\o4w_env.bat"
start "GPSBabel" /B "%OSGEO4W_ROOT%"\\bin\\GPSBabelFE.exe %*
EOF

cat <<EOF >postinstall.bat
for %%i in ("%OSGEO4W_ROOT%") do set O4W_ROOT=%%~fsi

if not defined OSGEO4W_DESKTOP for /F "tokens=* USEBACKQ" %%F IN (\`getspecialfolder Desktop\`) do set OSGEO4W_DESKTOP=%%F
for /F "tokens=* USEBACKQ" %%F IN (\`getspecialfolder Documents\`) do set DOCUMENTS=%%F

if not %OSGEO4W_MENU_LINKS%==0 if not exist "%OSGEO4W_STARTMENU%" mkdir "%OSGEO4W_STARTMENU%"
if not %OSGEO4W_DESKTOP_LINKS%==0 if not exist "%OSGEO4W_DESKTOP%" mkdir "%OSGEO4W_DESKTOP%"

if not %OSGEO4W_MENU_LINKS%==0 xxmklink "%OSGEO4W_STARTMENU%\\GPSBabel.lnk" "%O4W_ROOT%\\bin\\bgspawn.exe" "%O4W_ROOT%\\bin\\$P-gui.bat" "%DOCUMENTS%"
if not %OSGEO4W_DESKTOP_LINKS%==0 xxmklink "%OSGEO4W_DESKTOP%\\GPSBabel.lnk" "%O4W_ROOT%\\bin\\bgspawn.exe" "%O4W_ROOT%\\bin\\$P-gui.bat" "%DOCUMENTS%"
EOF

cat <<EOF >preremove.bat
del "%OSGEO4W_STARTMENU%\\GPSBabel.lnk"
del "%OSGEO4W_DESKTOP%\\GPSBabel.lnk"
del "%OSGEO4W_ROOT%\\bin\\$P-gui.bat"
EOF

tar -cvjf $R/$P-$V-$B.tar.bz2 \
	--xform "s,build/,bin/," \
	build/gpsbabel.exe

tar -cjf $R/$P-gui/$P-gui-$V-$B.tar.bz2 \
	--xform "s,build/gui/GPSBabelFE.exe,bin/gpsbabelfe.exe," \
	--xform "s,../gui/coretool/,apps/qt5/translations/," \
	--xform "s,../gui/,apps/qt5/translations/," \
	--xform "s,postinstall.bat,etc/postinstall/$P-gui.bat," \
	--xform "s,preremove.bat,etc/preremove/$P-gui.bat," \
	--xform "s,gui.bat,bin/$P-gui.bat," \
	build/gui/GPSBabelFE.exe \
	postinstall.bat \
	preremove.bat \
	gui.bat

cp ../$P-$V/COPYING $R/$P-$V-$B.txt
cp ../$P-$V/COPYING $R/$P-gui/$P-gui-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 \
	osgeo4w/package.sh

endlog
