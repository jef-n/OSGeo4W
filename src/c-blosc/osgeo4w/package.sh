export P=c-blosc
export V=1.21.6
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="lz4-devel zstd-devel zlib-devel"
export PACKAGES="c-blosc c-blocs-devel"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget -O $P-$V.tar.gz https://github.com/Blosc/$P/archive/refs/tags/v$V.tar.gz
[ -d ../$P-$V ] || tar -C .. -xzf $P-$V.tar.gz

(
	vsenv
	cmakeenv
	ninjaenv

	mkdir -p build install
	cd build

	export INCLUDE="$(cygpath -aw ../osgeo4w/include);$INCLUDE"
	export LIB="$(cygpath -aw ../osgeo4w/lib);$LIB"

	cmake -G Ninja \
		-D CMAKE_BUILD_TYPE=Release \
		-D CMAKE_INSTALL_PREFIX=../install \
		-D PREFER_EXTERNAL_LZ4=ON \
		-D PREFER_EXTERNAL_ZLIB=ON \
		-D PREFER_EXTERNAL_ZSTD=ON \
		../../$P-$V
	cmake --build .
	cmake --install .
)

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "A fast, compressed and persistent data store library for C (runtime)"
ldesc: "A fast, compressed and persistent data store library for C (runtime)"
category: Libs
requires: msvcrt2019 lz4 zstd zlib
maintainer: $MAINTAINER
EOF

cp ../$P-$V/LICENSE.txt $R/$P-$V-$B.txt
tar -C install -cjf $R/$P-$V-$B.tar.bz2 bin/blosc.dll

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "A fast, compressed and persistent data store library for C (development)"
ldesc: "A fast, compressed and persistent data store library for C (development)"
category: Libs
requires: $P
maintainer: $MAINTAINER
external-source: $P
EOF

cp ../$P-$V/LICENSE.txt $R/$P-devel/$P-devel-$V-$B.txt
tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 include lib

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
