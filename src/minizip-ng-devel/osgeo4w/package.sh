export P=minizip-ng-devel
export V=4.0.4
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="zlib-devel xz-devel bzip2-devel"
export PACKAGES="minizip-ng-devel"

source ../../../scripts/build-helpers

startlog

p=${P%-devel}
[ -f $p-$V.tar.gz ] || wget -O $p-$V.tar.gz https://github.com/zlib-ng/$p/archive/refs/tags/$V.tar.gz
[ -f ../$p-$V/CMakeLists.txt ] || tar -C .. -xzf $p-$V.tar.gz

vsenv
cmakeenv
ninjaenv

mkdir -p build install
cd build

export INCLUDE="$(cygpath -aw ../osgeo4w/include);$INCLUDE"
export LIB="$(cygpath -aw ../osgeo4w/lib);$LIB"

cygpath -am ../osgeo4w/lib/cmake/zstd

cmake -G Ninja \
	-D CMAKE_BUILD_TYPE=Release \
	-D CMAKE_INSTALL_PREFIX=../install \
	-D MZ_FETCH_LIBS=OFF \
	../../$p-$V
ninja
ninja install
cmakefix ../install

cd ..

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R

cat <<EOF >$R/setup.hint
sdesc: "zip manipulation library (development)"
category: Libs
requires: zlib xz
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 include lib
cp ../$p-$V/LICENSE $R/$P-$V-$B.txt
tar      -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
