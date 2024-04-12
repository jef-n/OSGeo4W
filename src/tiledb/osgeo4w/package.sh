export P=tiledb
export V=2.8.2
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="base bzip2-devel lz4-devel zlib-devel zstd-devel spdlog-devel"
export PACKAGES="tiledb tiledb-devel"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget -O $P-$V.tar.gz https://github.com/TileDB-Inc/TileDB/archive/refs/tags/$V.tar.gz
[ -d ../TileDB-$V ] || tar -C .. -xzf $P-$V.tar.gz

(
	set -x

	fetchenv osgeo4w/bin/o4w_env.bat

	vsenv
	ninjaenv
	cmakeenv

	type ninja
	type cmake

	mkdir -p build install
	cd build

	cmake -G Ninja \
		-D CMAKE_BUILD_TYPE=Release \
		-D CMAKE_INSTALL_PREFIX=../install \
		-D TILEDB_SUPERBUILD=OFF \
		-D TILEDB_VERBOSE=ON \
		-D TILEDB_TESTS=OFF \
		-D COMPILER_SUPPORTS_AVX2=OFF \
		-D LZ4_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
		-D LZ4_LIBRARIES=$(cygpath -am ../osgeo4w/lib/lz4.lib) \
		-D BZIP2_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
		-D BZIP2_LIBRARIES=$(cygpath -am ../osgeo4w/lib/libbz2.lib) \
		-D ZSTD_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
		-D ZSTD_LIBRARIES=$(cygpath -am ../osgeo4w/lib/zstd.lib) \
		-D ZLIB_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
		-D ZLIB_LIBRARY=$(cygpath -am ../osgeo4w/lib/zlib.lib) \
		-D spdlog_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
		-D spdlog_LIBRARY=$(cygpath -am ../osgeo4w/lib/spdlog.lib) \
		../../TileDB-$V
	cmake --build .
	cmake --install .
	cmakefix ../install
)

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "TileDB (runtime)"
ldesc: "TileDB (runtime)"
requires: 
category: Libs
maintainer: $MAINTAINER
EOF

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "TileDB (development)"
ldesc: "TileDB (development)"
category: Libs
requires: $P
maintainer: $MAINTAINER
external-source: $P
EOF

cp ../$P-$V/LICENSE $R/$P-$V-$B.txt
tar -C install -cjf $R/$P-$V-$B.tar.bz2 bin

cp ../$P-$V/LICENSE $R/$P-devel/$P-devel-$V-$B.txt
tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 include lib

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
