export P=libmysql
export V=8.2.0
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="openssl-devel zlib-devel zstd-devel curl-devel icu-devel"
export PACKAGES="libmysql libmysql-devel"

source ../../../scripts/build-helpers

startlog

p=${P#lib}
[ -f $p-boost-$V.tar.gz ] || wget https://downloads.mysql.com/archives/get/p/23/file/$p-boost-$V.tar.gz
[ -f ../$p-$V/CMakeLists.txt ] || tar -C .. -xzf $p-boost-$V.tar.gz

vsenv
cmakeenv
ninjaenv

mkdir -p build install
cd build

cmake -G Ninja \
	-D CMAKE_BUILD_TYPE=RelWithDebInfo \
	-D CMAKE_INSTALL_PREFIX=../install \
	-D WITH_BOOST=../../$p-$V/boost \
	-D WITH_SSL=yes \
	-D OPENSSL_ROOT_DIR=$(cygpath -am ../osgeo4w/) \
	-D WITHOUT_SERVER=ON \
	../../$p-$V

cmake --build .
cmake --build . --target install
cmakefix ../install

cd ..

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "MySQL Client Library (Runtime)"
ldesc: "MySQL Client Library (Runtime)"
category: Libs
requires: msvcrt2019 openssl
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	--xform "s,^lib,bin," \
	lib/libmysql.dll

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "MySQL Client Library (Development)"
ldesc: "MySQL Client Library (Development)"
category: Libs
requires: $P
external-source: $P
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	--exclude "lib/libmysql.dll" \
	--exclude "include/openssl/applink.c" \
	include lib

cp ../$p-$V/LICENSE $R/$P-$V-$B.txt
cp ../$p-$V/LICENSE $R/$P-devel/$P-devel-$P-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
