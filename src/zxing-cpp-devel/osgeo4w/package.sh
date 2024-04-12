export P=zxing-cpp-devel
export V=2.2.1
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none
export PACKAGES=zxing-cpp-devel

source ../../../scripts/build-helpers

startlog

p=${P%-devel}
[ -f $p-$V.tar.gz ] || wget -O $p-$V.tar.gz https://github.com/$p/$p/archive/refs/tags/v$V.tar.gz
[ -d ../$p-$V ] || tar -C .. -xzf $p-$V.tar.gz

vsenv
cmakeenv
ninjaenv

mkdir -p build install

cd build

cmake -G Ninja \
	-D CMAKE_BUILD_TYPE=Release \
	-D CMAKE_INSTALL_PREFIX=$(cygpath -am ../install) \
	../../$p-$V
cmake --build .
cmake --build . --target install
cmakefix ../install/lib/cmake

cd ..

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R

cat <<EOF >$R/setup.hint
sdesc: "C++ port of ZXing (development)"
ldesc: "C++ port of ZXing (development)"
maintainer: JuergenFischer
category: Libs
requires: msvcrt2019
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	lib/cmake \
	lib/ZXing.lib \
	include

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

cp ../$p-$V/LICENSE $R/$P-$V-$B.txt

endlog
