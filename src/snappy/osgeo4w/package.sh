export P=snappy
export V=1.1.9
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget -O $P-$V.tar.gz https://github.com/google/$P/archive/refs/tags/$V.tar.gz
[ -d ../$P-$V ] || tar -C .. -xzf $P-$V.tar.gz

(
	vs2019env
	cmakeenv
	ninjaenv

	mkdir -p build install
	cd build

	cmake -G Ninja \
		-D CMAKE_BUILD_TYPE=Release \
		-D CMAKE_INSTALL_PREFIX=../install \
		-D PROJECT_BINARY_DIR=share \
		-D SNAPPY_BUILD_TESTS=OFF \
		-D SNAPPY_BUILD_BENCHMARKS=OFF \
		../../$P-$V
	cmake --build .
	cmake --install .
)

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "snappy compression (development)"
ldesc: "snappy compression (development)"
category: Libs
requires: msvcrt2019
maintainer: $MAINTAINER
EOF

cp ../$P-$V/COPYING $R/$P-$V-$B.txt
tar -C install -cjf $R/$P-$V-$B.tar.bz2 include lib

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "snappy compression (development)"
ldesc: "snappy compression (development)"
category: Libs
requires: $P
maintainer: $MAINTAINER
external-source: $P
EOF

cp ../$P-$V/COPYING $R/$P-devel/$P-devel-$V-$B.txt
tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	--xform "s,lib/cmake,share/cmake," \
	include \
	lib

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
