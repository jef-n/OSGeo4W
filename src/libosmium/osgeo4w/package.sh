export P=libosmium
export V=2.19.0
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="protozero-devel boost-devel bzip2-devel zlib-devel lz4-devel expat-devel gdal-devel proj-devel"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget -O $P-$V.tar.gz https://github.com/osmcode/$P/archive/refs/tags/v$V.tar.gz
[ -f ../$P-$V/CMakeLists.txt ] || tar -C .. -xzf $P-$V.tar.gz

(
	vs2019env
	cmakeenv
	ninjaenv

	export LIB="$(cygpath -am osgeo4w/lib);$LIB"
	export INCLUDE="$(cygpath -am osgeo4w/include);$INCLUDE"

	mkdir -p build install
	cd build

	cmake -G Ninja \
		-D CMAKE_BUILD_TYPE=Release \
		-D CMAKE_INSTALL_PREFIX=../install \
		-D CMAKE_CXX_STANDARD=17 \
		-D Boost_USE_STATIC_LIBS=ON \
		-D Boost_USE_MULTITHREADED=ON \
		-D Boost_USE_STATIC_RUNTIME=OFF \
		-D Boost_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include/boost-1_74) \
		-D Boost_LIBRARY_DIR="$(cygpath -am ../osgeo4w/lib)" \
		-D EXPAT_LIBRARY=$(cygpath -am ../osgeo4w/lib/libexpat.lib) \
		-D LZ4_LIBRARY=$(cygpath -am ../osgeo4w/lib/lz4.lib) \
		../../$P-$V
	cmake --build .
	cmake --build . --target install
)

export R=$OSGEO4W_REP/x86_64/release/$P-devel
mkdir -p $R

cat <<EOF >$R/setup.hint
sdesc: "A fast and flexible C++ library for working with OpenStreetMap data. (development)"
ldesc: "A fast and flexible C++ library for working with OpenStreetMap data."
category: Commandline_Utilities
maintainer: $MAINTAINER
requires: msvcrt2019 expat proj zlib lz4 $RUNTIMEDEPENDS
EOF

tar -C install -cjf $R/$P-devel-$V-$B.tar.bz2 include

cp ../$P-$V/LICENSE $R/$P-devel-$V-$B.txt

tar -C .. -cjf $R/$P-devel-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
