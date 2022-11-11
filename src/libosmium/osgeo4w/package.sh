export P=libosmium
export V=2.18.0
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="expat-devel zlib-devel bzip2-devel boost-devel protozero-devel gdal-devel lz4-devel"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget -O $P-$V.tar.gz https://github.com/osmcode/$P/archive/refs/tags/v$V.tar.gz
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
		-D PROTOZERO_INCLUDE_DIR=$(cygpath -aw ../osgeo4w/include) \
		-D LZ4_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
		-D LZ4_LIBRARY=$(cygpath -am ../osgeo4w/lib/lz4.lib) \
		-D WITH_PROJ=OFF \
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
requires:
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-devel-$V-$B.tar.bz2 include

cp ../$P-$V/LICENSE $R/$P-devel-$V-$B.txt

tar -C .. -cjf $R/$P-devel-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
