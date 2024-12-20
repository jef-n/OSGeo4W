export P=qtwebkit
export V=5.212.0-alpha4
export B="next qtwebkit-libs"
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="qt5-devel icu-devel python3-core sqlite3-devel libjpeg-turbo-devel libpng-devel zlib-devel libxml2-devel libwebp-devel libiconv-devel"
export PACKAGES="qtwebkit-devel qtwebkit-libs qtwebkit-symbols"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.xz ] || wget -q -O $P-$V.tar.xz https://github.com/$P/$P/releases/download/$P-$V/$P-$V.tar.xz
[ -f ../$P-$V/CMakeLists.txt ] || tar -C .. -xJf $P-$V.tar.xz
[ -f ../$P-$V/patched ] || {
	patch -d ../$P-$V -p1 --dry-run <$P.diff
	patch -d ../$P-$V -p1 <$P.diff >../$P-$V/patched
}

mkdir -p build install

(
	fetchenv osgeo4w/bin/o4w_env.bat
	vsenv
	cmakeenv
	ninjaenv

        [ -x osgeo4w/bin/gperf.exe ] || {
                [ -f gperf-3.0.1.zip ] || curl -LO https://altushost-swe.dl.sourceforge.net/project/gnuwin32/gperf/3.0.1/gperf-3.0.1-bin.zip
                unzip -p gperf-3.0.1-bin.zip bin/gperf.exe >osgeo4w/bin/gperf.exe
                chmod a+rx osgeo4w/bin/gperf.exe
        }

	type -a gperf
	type -p ruby
	type -p python

	export INCLUDE="$(cygpath -aw osgeo4w/include);$INCLUDE"
	export LIB="$(cygpath -aw osgeo4w/lib);$LIB"

	cd build

	[ -f CMakeCache.txt ] || cmake -G Ninja \
		-Wno-dev \
		-D CMAKE_VERBOSE_MAKEFILE=ON \
		-D PORT=Qt \
		-D CMAKE_BUILD_TYPE=RelWithDebInfo \
		-D ENABLE_XSLT=OFF \
		-D CMAKE_INSTALL_PREFIX=$(cygpath -am ../install/apps/Qt5) \
		-D PYTHON_EXECUTABLE=$(cygpath -am ../osgeo4w/bin/python.exe) \
		-D SQLITE_LIBRARIES=$(cygpath -am ../osgeo4w/lib/sqlite3_i.lib) \
		-D JPEG_LIBRARY="$(cygpath -am ../osgeo4w/lib/jpeg.lib)" \
		-D PNG_PNG_INCLUDE_DIR="$(cygpath -am ../osgeo4w/include)" \
		-D PNG_LIBRARY="$(cygpath -am ../osgeo4w/lib/libpng16.lib)" \
		-D ZLIB_LIBRARY="$(cygpath -am ../osgeo4w/lib/zlib.lib)" \
		-D ICU_INCLUDE_DIR="$(cygpath -am ../osgeo4w/include)" \
		-D ICU_LIBRARY="$(cygpath -am ../osgeo4w/lib/icuuc.lib)" \
		-D PC_ICU_LIBRARY_DIRS="$(cygpath -am ../osgeo4w/lib)" \
		-D PC_ICU_INCLUDE_DIRS="$(cygpath -am ../osgeo4w/include)" \
		-D ICU_I18N_LIBRARY="$(cygpath -am ../osgeo4w/lib/icuin.lib)" \
		../../$P-$V
	touch ../configured

	[ -f ../built ] || ninja -k 10 || ninja
	touch ../built

	[ -f ../installed ] || {
		ninja install
		cmakefix ../install
		sed -i -e "s#$(cygpath -am ../install)#\$\$(OSGEO4W_ROOT)#g" ../install/apps/qt5/mkspecs/modules/*.pri
	}
	touch ../installed
)

export R=$OSGEO4W_REP/x86_64/release/qt5/$P
mkdir -p $R/$P-{libs,devel,symbols}

cat <<EOF >$R/$P-libs/setup.hint
sdesc: "WebKit for Qt5 (runtime)"
ldesc: "WebKit for Qt5 (runtime)"
maintainer: $MAINTAINER
category: Libs
requires: msvcrt2019 qt5-libs icu
external-source: $P
EOF

tar -C install -cjf $R/$P-libs/$P-libs-$V-$B.tar.bz2 \
	--exclude "*.pdb" \
	apps/Qt5/bin/ \
	apps/Qt5/lib/qml/

cp ../$P-$V/LICENSE.LGPLv21 $R/$P-libs/$P-libs-$V-$B.txt

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "WebKit for Qt5 (development)"
ldesc: "WebKit for Qt5 (development)"
maintainer: $MAINTAINER
category: Libs
requires: $P-libs
external-source: $P
EOF

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	apps/Qt5/mkspecs \
	apps/Qt5/include \
	apps/Qt5/lib/cmake \
	apps/Qt5/lib/pkgconfig \
	apps/Qt5/lib/Qt5WebKit.lib \
	apps/Qt5/lib/Qt5WebKitWidgets.lib

cp ../$P-$V/LICENSE.LGPLv21 $R/$P-devel/$P-devel-$V-$B.txt

cat <<EOF >$R/$P-symbols/setup.hint
sdesc: "WebKit for Qt5 (symbols)"
ldesc: "WebKit for Qt5 (symbols)"
maintainer: $MAINTAINER
category: Libs
requires: $P-libs
external-source: $P
EOF

tar -C install -cjf $R/$P-symbols/$P-symbols-$V-$B.tar.bz2 \
	apps/Qt5/bin/Qt5WebKit.pdb \
	apps/Qt5/bin/Qt5WebKitWidgets.pdb

cp ../$P-$V/LICENSE.LGPLv21 $R/$P-symbols/$P-symbols-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh osgeo4w/$P.diff

#
# check
#

cd install

find apps -type f >/tmp/$P.installed

for i in libs devel symbols; do
	tar tjf $R/$P-$i/$P-$i-$V-$B.tar.bz2 | grep -v "/$" | tee /tmp/$P-$i.packaged
done >/tmp/$P.packaged

sort /tmp/$P.packaged | uniq -d >/tmp/$P.dupes
if [ -s $P.dupes ]; then
	echo Duplicate files:
	cat /tmp/$P.dupes
fi

if fgrep -vxf /tmp/$P.installed /tmp/$P.packaged >/tmp/$P.generated;  then
	echo Generated files:
	cat /tmp/$P.generated
fi

if fgrep -vxf /tmp/$P.packaged /tmp/$P.installed >/tmp/$P.missing;  then
	echo Not packaged files:
	cat /tmp/$P.missing
fi

! [ -s /tmp/$P.dupes ] && ! [ -s /tmp/$P.generated ] && ! [ -s /tmp/$P.missing ]

endlog
