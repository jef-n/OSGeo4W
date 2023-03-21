export P=osm2pgsql
export V=1.8.1
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="expat-devel proj-devel bzip2-devel zlib-devel boost-devel libpq-devel wingetopt-devel lua-devel"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget -O $P-$V.tar.gz https://github.com/openstreetmap/$P/archive/refs/tags/$V.tar.gz
[ -f ../$P-$V/CMakeLists.txt ] || tar -C .. -xzf $P-$V.tar.gz

(
	vs2019env
	cmakeenv
	ninjaenv

	mkdir -p build install
	cd build

	export LIB="$(cygpath -am osgeo4w/lib);$LIB"
	export INCLUDE="$(cygpath -am osgeo4w/include);$INCLUDE"

	cmake -G Ninja \
		-D CMAKE_BUILD_TYPE=Release \
		-D CMAKE_INSTALL_PREFIX=../install \
		-D CMAKE_CXX_STANDARD=17 \
		-D EXPAT_LIBRARY=$(cygpath -am ../osgeo4w/lib/libexpat.lib) \
		-D EXPAT_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
		-D ZLIB_INCLUDE_DIR=$(cygpath -aw ../osgeo4w/include) \
		-D ZLIB_LIBRARY=$(cygpath -aw ../osgeo4w/lib/zlib.lib) \
		-D BZIP2_LIBRARIES=$(cygpath -am ../osgeo4w/lib/libbz2.lib) \
		-D BZIP2_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
		-D LUA_LIBRARIES=$(cygpath -am ../osgeo4w/lib/lua*.lib) \
		-D LUA_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include/lua*) \
		-D Boost_USE_STATIC_LIBS=ON \
		-D Boost_USE_MULTITHREADED=ON \
		-D Boost_USE_STATIC_RUNTIME=OFF \
		-D Boost_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include/boost-1_74) \
		-D Boost_LIBRARY_DIR="$(cygpath -am ../osgeo4w/lib)" \
		-D PROJ6_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
		-D PROJ6_LIBRARY=$(cygpath -am ../osgeo4w/lib/proj.lib) \
		-D GETOPT_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
		-D GETOPT_LIBRARY=$(cygpath -am ../osgeo4w/lib/wingetopt.lib) \
		../../$P-$V
	cmake --build .
	cmake --build . --target install
)

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R

cat <<EOF >$R/setup.hint
sdesc: "OpenStreetMap data to PostgreSQL converter"
ldesc: "OpenStreetMap data to PostgreSQL converter"
category: Commandline_Utilities
requires: msvcrt2019
maintainer: $MAINTAINER
requires: msvcrt2019 libpq expat proj zlib lua
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	bin \
	share

cp ../$P-$V/COPYING $R/$P-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
