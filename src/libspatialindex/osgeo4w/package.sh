export P=libspatialindex
export V=1.9.3
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none
export PACKAGES="libspatialindex libspatialindex-devel"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget -O $P-$V.tar.gz https://github.com/$P/$P/archive/$V.tar.gz
[ -f ../$P-$V/CMakeLists.txt ] || tar -C .. -xzf $P-$V.tar.gz

vsenv
cmakeenv
ninjaenv

mkdir -p build install
cd build

cmake -G Ninja \
	-D CMAKE_BUILD_TYPE=Release \
	-D CMAKE_INSTALL_PREFIX=../install \
	../../$P-$V
ninja
ninja install
cmakefix ../install

cd ..

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "The libspatialindex library (Runtime)"
ldesc: "libspatialindex is a LGPL library that implements R-Tree, MVRTree, and TPRTree spatial indexing algorithms"
category: Libs
requires: msvcrt2019
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 bin

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "The libspatialindex library (Development)"
ldesc: "libspatialindex is a LGPL library that implements R-Tree, MVRTree, and TPRTree spatial indexing algorithms"
category: Libs
requires: $P
maintainer: $MAINTAINER
external-source: $P
EOF

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 include lib
tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

cp ../$P-$V/COPYING $R/$P-$V-$B.txt
cp ../$P-$V/COPYING $R/$P-devel/$P-devel-$V-$B.txt

endlog
