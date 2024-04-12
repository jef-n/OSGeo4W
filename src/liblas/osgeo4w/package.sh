export P=liblas
export V=1.8.1
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="gdal-devel boost-devel libjpeg-turbo-devel libtiff-devel libgeotiff-devel zlib-devel"
export PACKAGES="liblas liblas-devel"

source ../../../scripts/build-helpers

startlog

[ -f libLAS-$V.tar.bz2 ] || wget http://download.osgeo.org/$P/libLAS-$V.tar.bz2
[ -f ../libLAS-$V/CMakeLists.txt ] || tar -C .. -xjf libLAS-$V.tar.bz2
[ -f ../libLAS-$V/patched ] || {
	patch -d ../libLAS-$V -p1 --dry-run <patch
	patch -d ../libLAS-$V -p1 <patch >../libLAS-$V/patched
}

(
	fetchenv osgeo4w/bin/o4w_env.bat
	vsenv
	cmakeenv
	ninjaenv

	mkdir -p build install

	export INCLUDE="$(cygpath -aw $OSGEO4W_PWD/osgeo4w/include);$(cygpath -aw ../osgeo4w/include/boost-1_84);$INCLUDE"
	export LIB="$(cygpath -aw $OSGEO4W_PWD/osgeo4/lib);$LIB"

	cd build

	cmake -G Ninja \
		-D CMAKE_BUILD_TYPE=Release \
		-D CMAKE_INSTALL_PREFIX=../install \
		-D WITH_TESTS=OFF \
		-D BUILD_OSGEO4W=OFF \
		-D JPEG_LIBRARY=$(cygpath -am ../osgeo4w/lib/jpeg.lib) \
		../../libLAS-$V
	cmake --build .
	cmake --build . --target install
	cmakefix ../install
)

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "The libLAS commandline utilities"
ldesc: "libLAS is a library for manipulating LAS 1.0, 1.1, and 1.2 LiDAR data files"
category: Commandline_Utilities
category: Libs
requires: msvcrt2019 $RUNTIMEDEPENDS libjpeg-turbo libtiff libgeotiff zlib
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	bin doc

cp ../libLAS-$V/LICENSE.txt $R/$P-$V-$B.txt

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "The libLAS commandline development files"
ldesc: "libLAS is a library for manipulating LAS 1.0, 1.1, and 1.2 LiDAR data files"
category: Libs
requires: $P
maintainer: $MAINTAINER
external-source: $P
EOF

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	include lib cmake

cp ../libLAS-$V/LICENSE.txt $R/$P-devel/$P-devel-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh osgeo4w/patch

endlog
