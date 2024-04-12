export P=uriparser-devel
export V=0.9.7
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none
export PACKAGES="uriparser-devel"

source ../../../scripts/build-helpers

startlog

p=${P%-devel}
[ -f $p-$V.tar.gz ] || wget -O $p-$V.tar.gz https://github.com/$p/$p/releases/download/$p-$V/$p-$V.tar.gz
[ -f ../$p-$V/CMakeLists.txt ] || tar -C .. -xzf $p-$V.tar.gz

vsenv
cmakeenv
ninjaenv

mkdir -p build install

cd build

# we only need a static library for libkml
cmake -G Ninja \
	-D CMAKE_BUILD_TYPE=Release \
	-D CMAKE_INSTALL_PREFIX=../install \
	-D URIPARSER_BUILD_TESTS=OFF \
	-D BUILD_SHARED_LIBS=OFF \
        -D URIPARSER_BUILD_TOOLS=OFF \
	-D URIPARSER_BUILD_DOCS=OFF \
	../../$p-$V
cmake --build .
cmake --build . --target install
cmakefix ../install

cd ..

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R

cat <<EOF >$R/setup.hint
sdesc: "URI parsing and handling library (Development)"
ldesc: "strictly RFC 3986 compliant URI parsing and handling library (Runtime)"
category: Libs
requires: 
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	include \
	lib

cp ../$p-$V/COPYING $R/$P-$P-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
