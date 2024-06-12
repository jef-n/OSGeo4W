export P=qfield-dev
export V=99
export B=tbd
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="qt6-devel qt6-tools qt6-oci qt6-qml qca-qt6-devel gdal-dev-devel proj-devel qgis-qt6-dev qtkeychain-qt6-devel libpq-devel protobuf-devel exiv2-devel draco-devel expat-devel libzip-devel libzip-tools libspatialindex-devel sqlite3-devel poly2tri-devel zxing-cpp-devel"
export PACKAGES=qfield-dev

: ${REPO:=https://github.com/opengisch/QField.git}
: ${CC:=cl.exe}
: ${CXX:=cl.exe}
: ${BUILDCONF:=RelWithDebInfo}

export CC CXX BUILDCONF

source ../../../scripts/build-helpers

startlog

cd ..

if [ -d qfield ]; then
	cd qfield
	git config core.filemode false

	if [ -z "$OSGEO4W_SKIP_CLEAN" ]; then
		git clean -f
		git reset --hard

		git config pull.rebase false

		i=0
		until (( i > 10 )) || git pull; do
			(( ++i ))
		done
	fi
else
	git clone $REPO --branch master --single-branch --depth 1 qfield
	cd qfield
	git config core.filemode false
	unset OSGEO4W_SKIP_CLEAN
fi

if [ -z "$OSGEO4W_SKIP_CLEAN" ]; then
	if ! git apply --check --reverse ../osgeo4w/patch; then
		git apply --check ../osgeo4w/patch
		git apply ../osgeo4w/patch
	fi
fi

SHA=$(git log -n1 --pretty=%h)

availablepackageversions $P
# Version: 99-$BUILD-$SHA-$BINARY

build=1
if [[ "$version_curr" =~ .*-.*-.* ]]; then
	v=$version_curr
	version=${v%%-*}
	v=${v#*-}

	build=${v%%-*}
	v=${v#*-}
	sha=${v%%-*}

	if [ "$SHA" = "$sha" -a -z "$OSGEO4W_FORCE_REBUILD" ]; then
		echo "$SHA already built."
		endlog
		exit 0
	fi

	if [ "$V" = "$version" ]; then
		(( ++build ))
	fi
fi

V=$V-$build-$SHA
nextbinary

(
	set -e
	set -x

	cd $OSGEO4W_PWD

	fetchenv osgeo4w/bin/o4w_env.bat
	fetchenv osgeo4w/bin/qt6_env.bat
	fetchenv osgeo4w/bin/gdal-dev-env.bat

	vsenv
	cmakeenv
	ninjaenv
	ccacheenv

	mkdir -p build install

	cd build

	export INCLUDE="$(cygpath -aw $OSGEO4W_ROOT/apps/qgis-qt6-dev/include);$(cygpath -aw $OSGEO4W_ROOT/apps/Qt6/include);$(cygpath -aw $OSGEO4W_ROOT/apps/gdal-dev/include);$(cygpath -aw $OSGEO4W_ROOT/include);$INCLUDE"
	export LIB="$(cygpath -aw $OSGEO4W_ROOT/apps/qgis-qt6-dev/lib);$(cygpath -aw $OSGEO4W_ROOT/apps/Qt6/lib);$(cygpath -aw $OSGEO4W_ROOT/apps/gdal-dev/lib);$(cygpath -aw $OSGEO4W_ROOT/lib);$LIB"

	cmake -G Ninja \
		-D CMAKE_BUILD_TYPE=$BUILDCONF \
		-D CMAKE_FIND_DEBUG_MODE=ON \
		-D CMAKE_INSTALL_PREFIX=$(cygpath -am ../install/apps/$P) \
		-D WITH_CCACHE=ON \
		-D Qca_DIR=$(cygpath -am ../osgeo4w/apps/Qt6) \
		../../qfield

	cmake --build .
	cmake --build . --target install
)

cd ../osgeo4w

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R

cat <<EOF >$R/setup.hint
sdesc: "QField"
ldesc: "Nightly build of QField development branch"
maintainer: $MAINTAINER
category: Desktop
requires: msvcrt2019 base qt6-libs qca-qt6-libs qtkeychain-qt6 qt6-oci qgis-qt6-dev sqlite3 $RUNTIMEDEPENDS
EOF

mkdir -p install/{bin,etc/{postinstall,preremove}}

cat <<EOF >install/bin/$P.bat
@echo off
call "%~dp0\\o4w_env.bat"
call qt6_env.bat
call gdal-dev-env.bat
path %OSGEO4W_ROOT%\\apps\\$P\\bin;%OSGEO4W_ROOT%\\apps\\qgis-qt6-dev\\bin;%PATH%
set QGIS_PREFIX_PATH=%OSGEO4W_ROOT%\\apps\\qgis-qt6-dev
start "QField" /B "%OSGEO4W_ROOT%\\apps\\$P\\bin\\qfield.exe" %*
EOF

cat <<EOF >install/etc/postinstall/$P.bat
call "%OSGEO4W_ROOT%\\bin\\o4w_env.bat"

if not %OSGEO4W_MENU_LINKS%==0 if not exist "%OSGEO4W_STARTMENU%" mkdir "%OSGEO4W_STARTMENU%"
if not %OSGEO4W_DESKTOP_LINKS%==0 if not exist "%OSGEO4W_DESKTOP%" mkdir "%OSGEO4W_DESKTOP%"

if not %OSGEO4W_MENU_LINKS%==0 xxmklink "%OSGEO4W_STARTMENU%\\QField $V.lnk" "%OSGEO4W_ROOT%\\bin\\bgspawn.exe" "\"%OSGEO4W_ROOT%\\bin\\$P.bat\"" "%DOCUMENTS%" "" 1 "%OSGEO4W_ROOT%\\apps\\$P\\bin\\qfield.exe"
if not %OSGEO4W_DESKTOP_LINKS%==0 xxmklink "%OSGEO4W_DESKTOP%\\QField $V.lnk" "%OSGEO4W_ROOT%\\bin\\bgspawn.exe" "\"%OSGEO4W_ROOT%\\bin\\$P.bat\"" "%DOCUMENTS%" "" 1 "%OSGEO4W_ROOT%\\apps\\$\\bin\\qfield.exe"
exit /b 0
EOF

cat <<EOF >install/etc/preremove/$P.bat
del "%OSGEO4W_STARTMENUl%\\QField $V.lnk"
del "%OSGEO4W_STARTMENU%\\QField $V.lnk"
rmdir "%OSGEO4W_STARTMENU%"
del "%OSGEO4W_DESKTOP%\\QField $V.lnk"
del "%OSGEO4W_DESKTOP%\\QField $V.lnk"
rmdir "%OSGEO4W_DESKTOP%"
EOF

/bin/tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	apps/$P \
	bin/$P.bat \
	etc/postinstall/$P.bat \
	etc/preremove/$P.bat

/bin/tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 \
	osgeo4w/package.sh osgeo4w/patch

endlog
