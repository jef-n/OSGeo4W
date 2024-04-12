export P=libkml-devel
export V=1.3.0
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="zlib-devel expat-devel boost-devel uriparser-devel"
export PACKAGES="libkml-devel"

source ../../../scripts/build-helpers

startlog

p=${P%-devel}
[ -f $p-$V.tar.gz ] || wget -O $p-$V.tar.gz https://github.com/$p/$p/archive/$V.tar.gz
[ -f ../$p-$V/CMakeLists.txt ] || tar -C .. -xzf $p-$V.tar.gz
[ -f ../$p-$V/patched ] || {
	patch -p1 -d ../$p-$V --dry-run <patch
	patch -p1 -d ../$p-$V <patch
	touch ../$p-$V/patched
}

vsenv
cmakeenv
ninjaenv

mkdir -p build install

export EP_BASE=$(cygpath -am external)

cd build

cmake -G Ninja \
	-D CMAKE_BUILD_TYPE=Release \
	-D CMAKE_INSTALL_PREFIX=../install \
	-D BUILD_SHARED_LIBS=OFF \
	-D CMAKE_CXX_FLAGS="/DWIN32 /D_WINDOWS /W3 /GR /EHsc /DURI_STATIC_BUILD" \
	-D CMAKE_C_FLAGS="/DWIN32 /D_WINDOWS /W3 /DURI_STATIC_BUILD" \
	-D EXPAT_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D EXPAT_LIBRARY=$(cygpath -am ../osgeo4w/lib/libexpat.lib) \
	-D ZLIB_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D ZLIB_LIBRARY=$(cygpath -am ../osgeo4w/lib/zlib.lib) \
	-D URIPARSER_LIBRARY=$(cygpath -am ../osgeo4w/lib/uriparser.lib) \
	-D URIPARSER_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include/uriparser) \
	-D Boost_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include/boost-1_84) \
	../../$p-$V
cmake --build .
cmake --build . --target install
cmakefix ../install

cd ..

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R

cat <<EOF >$R/setup.hint
sdesc: "LibKML (Development)"
ldesc: " LibKML (Development)"
category: Libs
requires: boost-devel uriparser-devel
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	cmake \
	include/kml \
	include/minizip \
	lib

cp ../$p-$V/COPYING $R/$P-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
