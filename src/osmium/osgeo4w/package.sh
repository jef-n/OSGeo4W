export P=osmium
export V=1.18.0
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="libosmium-devel protozero-devel boost-devel bzip2-devel zlib-devel lz4-devel expat-devel gdal-devel"
export PACKAGES="osmium"

source ../../../scripts/build-helpers

startlog

p=$P-tool

[ -f $p-$V.tar.gz ] || wget -O $p-$V.tar.gz https://github.com/osmcode/$p/archive/refs/tags/v$V.tar.gz
[ -f ../$p-$V/CMakeLists.txt ] || tar -C .. -xzf $p-$V.tar.gz
[ -f include/nlohmann/json.hpp ] || {
	mkdir -p include/nlohmann
	curl -JL --output include/nlohmann/json.hpp https://github.com/nlohmann/json/releases/download/v3.11.3/json.hpp
}

(
	fetchenv osgeo4w/bin/o4w_env.bat
	vsenv
	cmakeenv
	ninjaenv

	mkdir -p build install
	cd build

	export LIB="$(cygpath -am ../osgeo4w/lib);$LIB"
	export INCLUDE="$(cygpath -am ../include);$(cygpath -am ../osgeo4w/include);$INCLUDE"

	cmake -G Ninja \
		-D CMAKE_BUILD_TYPE=Release \
		-D CMAKE_INSTALL_PREFIX=../install \
		-D CMAKE_CXX_STANDARD=17 \
		-D NLOHMANN_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
		-D Boost_USE_STATIC_LIBS=ON \
		-D Boost_USE_MULTITHREADED=ON \
		-D Boost_USE_STATIC_RUNTIME=OFF \
		-D Boost_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include/boost-1_87) \
		-D Boost_LIBRARY_DIR="$(cygpath -am ../osgeo4w/lib)" \
		-D BZIP2_LIBRARY_RELEASE=$(cygpath -am ../osgeo4w/lib/libbz2.lib) \
		-D LZ4_LIBRARY_RELEASE=$(cygpath -am ../osgeo4w/lib/lz4.lib) \
		../../$p-$V
	cmake --build .

	if [ -z "$OSGEO4W_SKIP_TESTS" ]; then
		cmake --build . --target test
	fi

	cmake --build . --target install
	cmakefix ../install
)

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R

cat <<EOF >$R/setup.hint
sdesc: "A multipurpose command line tool for working with OpenStreetMap data based on the Osmium library."
ldesc: "A multipurpose command line tool for working with OpenStreetMap data based on the Osmium library."
category: Commandline_Utilities
maintainer: $MAINTAINER
requires: msvcrt2019 expat proj zlib lz4 $RUNTIMEDEPENDS
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 bin

cp ../$p-$V/LICENSE.txt $R/$P-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
