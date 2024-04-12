export P=xz
export V=5.4.5
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none
export PACKAGES="xz xz-devel"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.bz2 ] || wget -c -O $P-$V.tar.bz2 https://sourceforge.net/projects/lzmautils/files/$P-$V.tar.bz2
[ -f ../$P-$V/CMakeLists.txt ] || tar -C .. -xjf $P-$V.tar.bz2

vsenv
cmakeenv
ninjaenv

mkdir -p build install build-static

cd build

cmake -G Ninja \
	-D CMAKE_BUILD_TYPE=Release \
	-D CMAKE_INSTALL_PREFIX=../install \
	-D BUILD_SHARED_LIBS=ON \
	../../$P-$V

cmake --build .
cmake --build . --target install
cmakefix ../install

cd ../build-static

cmake -G Ninja \
	-D CMAKE_BUILD_TYPE=Release \
	../../$P-$V

cmake --build .

cd ..

cp build-static/liblzma.lib install/lib/liblzma_static.lib

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "XZ-format compression library - runtime files"
ldesc: "XZ-format compression library - runtime files"
maintainer: $MAINTAINER
requires: 
category: Libs
EOF

cp ../$P-$V/COPYING $R/$P-$V-$B.txt
tar -C install -cjvf $R/$P-$V-$B.tar.bz2 bin

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "XZ-format compression library - development files"
ldesc: "XZ-format compression library - development files"
maintainer: $MAINTAINER
requires: $P
category: Libs
EOF

cp ../$P-$V/COPYING $R/$P-devel/$P-devel-$V-$B.txt
tar -C install -cjvf $R/$P-devel/$P-devel-$V-$B.tar.bz2 include lib

tar -C .. -cjvf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
