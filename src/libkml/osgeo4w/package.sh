export P=libkml
export V=1.3.0
export B=next
export MAINTAINER=JuergenFischer

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget -O $P-$V.tar.gz https://github.com/$P/$P/archive/$V.tar.gz
[ -f ../CMakeLists.txt ] || tar -C .. -xzf $P-$V.tar.gz --xform "s,^$P-$V,.,"

fetchdeps zlib-devel expat-devel boost-devel

vs2019env
cmakeenv
ninjaenv

mkdir -p build install

export EP_BASE=$(cygpath -am external)

cd build

export CC=cl.exe
export CXX=cl.exe

cmake -G Ninja \
	-D CMAKE_BUILD_TYPE=Release \
	-D CMAKE_INSTALL_PREFIX=../install \
	-D BUILD_SHARED_LIBS=OFF \
	-D EXPAT_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D EXPAT_LIBRARY=$(cygpath -am ../osgeo4w/libexpat.lib) \
	-D ZLIB_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D ZLIB_LIBRARY=$(cygpath -am ../osgeo4w/lib/zlib.lib) \
	-D Boost_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include/boost-1_74) \
	../..
ninja
ninja install

cd ..

export R=$OSGEO4W_REP/x86_64/release/$P-devel
mkdir -p $R

cat <<EOF >$R/setup.hint
sdesc: "LibKML (Development)"
ldesc: " LibKML (Development)"
category: Libs
requires: 
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-devel-$V-$B.tar.bz2 \
	cmake \
	include/kml \
	include/minizip \
	include/uriparser \
	lib

cp ../COPYING $R/$P-devel-$V-$B.txt

tar -C .. -cjf $R/$P-devel-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
