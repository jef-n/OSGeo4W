export P=protobuf
export V=3.13.0
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=zlib-devel

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget -c -O $P-$V.tar.gz https://github.com/protocolbuffers/protobuf/archive/v$V.tar.gz
[ -d ../cmake ] || tar -C .. -xzf $P-$V.tar.gz --xform "s,^$P-$V,.,"

vs2019env
cmakeenv
ninjaenv

mkdir -p build install
cd build

cmake -G Ninja \
	-D CMAKE_BUILD_TYPE=Release \
	-D CMAKE_INSTALL_PREFIX=../install \
	-D protobuf_BUILD_SHARED_LIBS=ON \
	-D protobuf_BUILD_TESTS=OFF \
	-D ZLIB_LIBRARY=$(cygpath -am ../osgeo4w/lib/zlib.lib) \
	-D ZLIB_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	../../cmake
ninja
ninja install

cd ../install

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "Protocol Buffers - Google's data interchange format"
ldesc: "Protocol Buffers - Google's data interchange format"
category: Libs
requires: msvcrt2019 zlib
maintainer: $MAINTAINER
EOF

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "Protocol Buffers - Google's data interchange format (development)"
ldesc: "Protocol Buffers - Google's data interchange format (development)"
category: Libs
requires: $P
external-source: $P
maintainer: $MAINTAINER
EOF

cp ../../LICENSE $R/$P-$V-$B.txt
cp ../../LICENSE $R/$P-devel/$P-$V-$B.txt

tar -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 bin/*.exe cmake include lib
tar -cjf $R/$P-$V-$B.tar.bz2 bin/*.dll

cd ..

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh 

endlog
