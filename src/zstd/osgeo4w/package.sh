export P=zstd
export V=1.5.5
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none
export PACKAGES="zstd zstd-devel"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget -O $P-$V.tar.gz https://github.com/facebook/$P/archive/v$V.tar.gz
[ -f ../build/cmake/CMakeLists.txt ] || tar -C .. -xzf $P-$V.tar.gz

vsenv
cmakeenv
ninjaenv

mkdir -p build install

cd build

cmake -G Ninja \
	-D CMAKE_BUILD_TYPE=Release \
	-D CMAKE_INSTALL_PREFIX=../install \
	-D ZSTD_LEGACY_SUPPORT=ON \
	-D ZSTD_BUILD_PROGRAMS=OFF \
	../../$P-$V/build/cmake
ninja
ninja install
cmakefix ../install

cd ..

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "Zstandard Long Range Match Finder (runtime)"
ldesc: "Zstandard Long Range Match Finder (runtime)"
Maintainer: JuergenFischer
category: Libs
requires: msvcrt2019
external-source: zstd
EOF

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "Zstandard Long Range Match Finder (development)"
ldesc: "Zstandard Long Range Match Finder (development)"
Maintainer: $MAINTAINER
category: Libs
requires: zstd
external-source: zstd
EOF

cp ../$P-$V/COPYING $R/$P-$V-$B.txt
cp ../$P-$V/COPYING $R/$P-devel/$P-devel-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

tar -cjf $R/$P-$V-$B.tar.bz2 \
	--xform "s,build/lib/zstd.dll,bin/zstd.dll," \
	build/lib/zstd.dll

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	lib \
	include

endlog
