export P=protobuf-devel
export V=25.3
export B="next"
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=zlib-devel
export PACKAGES=protobuf-devel

source ../../../scripts/build-helpers

startlog

absv=20240116.1

p=${P%-devel}
[ -f $p-$V.tar.gz ] || wget -c -O $p-$V.tar.gz https://github.com/protocolbuffers/$p/releases/download/v$V/$p-$V.tar.gz
[ -f ../$p-$V/CMakeLists.txt ] || tar -C .. -xzf $p-$V.tar.gz
[ -f $absv.tar.gz ] || wget https://github.com/abseil/abseil-cpp/archive/refs/tags/$absv.tar.gz
[ -f ../$p-$V/third_party/abseil-cpp/CMakeLists.txt ] || tar -C ../$p-$V/third_party/abseil-cpp -xzf $absv.tar.gz --xform "s,^abseil-cpp-$absv/,,"

vsenv
cmakeenv
ninjaenv

mkdir -p build install
cd build

cmake -G Ninja \
	-D CMAKE_BUILD_TYPE=Release \
	-D CMAKE_INSTALL_PREFIX=../install \
	-D protobuf_BUILD_TESTS=OFF \
	-D protobuf_MSVC_STATIC_RUNTIME=OFF \
	-D ZLIB_LIBRARY=$(cygpath -am ../osgeo4w/lib/zlib.lib) \
	-D ZLIB_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	../../$p-$V
ninja
ninja install
cmakefix ../install

cd ../install

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R

cat <<EOF >$R/setup.hint
sdesc: "Protocol Buffers - Google's data interchange format (development)"
ldesc: "Protocol Buffers - Google's data interchange format (development)"
category: Libs
requires: msvcrt2019 zlib-devel
maintainer: $MAINTAINER
EOF

cp ../../$p-$V/LICENSE $R/$P-$V-$B.txt

tar -cjf $R/$P-$V-$B.tar.bz2 bin/*.exe cmake include lib

cd ..

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
