export P=libmysql
export V=8.0.21
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=openssl-devel

source ../../../scripts/build-helpers

startlog

p=${P#lib}
[ -f $p-$V.tar.gz ] || wget https://dev.mysql.com/get/Downloads/MySQL-${V%.*}/$p-$V.tar.gz
[ -f ../CMakeLists.txt ] || tar -C .. -xzf $p-$V.tar.gz --xform "s,^$p-$V,.,"

vs2019env
cmakeenv

mkdir -p build install
cd build

buildcfg=RelWithDebInfo

cmake -G "Visual Studio 16 2019" -A x64 -D MSVC_TOOLSET_VERSION=142 \
	-D CMAKE_CONFIGURATION_TYPES=$buildcfg \
	-D CMAKE_INSTALL_PREFIX=../install \
	-D DOWNLOAD_BOOST=1 -D WITH_BOOST=../boost \
	-D WITH_SSL=yes \
	-D OPENSSL_ROOT_DIR=$(cygpath -am ../osgeo4w/) \
	-D WITHOUT_SERVER=ON \
	../..
cd ..

cmake --build build --config $buildcfg
cmake --install build --config $buildcfg

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
	include lib

cp ../LICENSE $R/$P-$V-$B.txt
cp ../LICENSE $R/$P-devel/$P-devel-$P-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
