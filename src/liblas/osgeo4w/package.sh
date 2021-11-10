export P=liblas
export V=1.8.1
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="gdal-devel boost-devel libjpeg-devel libtiff-devel libgeotiff-devel zlib-devel"

source ../../../scripts/build-helpers

startlog

[ -f libLAS-$V.tar.bz2 ] || wget http://download.osgeo.org/$P/libLAS-$V.tar.bz2
[ -f ../libLAS-$V/CMakeLists.txt ] || tar -C .. -xjf  libLAS-$V.tar.bz2
[ -f ../libLAS-$V/patched ] || {
	patch -p1 -d ../libLAS-$V --dry-run <patch
	patch -p1 -d ../libLAS-$V <patch
	touch ../libLAS-$V/patched
}

(
	fetchenv osgeo4w/bin/o4w_env.bat
	vs2019env
	cmakeenv
	ninjaenv

	mkdir -p build install
	cd build

	cmake -G Ninja \
		-D CMAKE_BUILD_TYPE=Release \
		-D CMAKE_INSTALL_PREFIX=../install \
		-D WITH_TESTS=OFF \
		-D BUILD_OSGEO4W=OFF \
		-D JPEG_LIBRARY=$(cygpath -am ../osgeo4w/lib/jpeg_i.lib) \
		../../libLAS-$V
	ninja
	ninja install
)

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "The libLAS commandline utilities"
ldesc: "libLAS is a library for manipulating LAS 1.0, 1.1, and 1.2 LiDAR data files"
category: Commandline_Utilities
category: Libs
requires: msvcrt2019 $RUNTIMEDEPENDS libjpeg libtiff libgeotiff zlib
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

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
