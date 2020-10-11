export P=libpng
export V=1.6.37
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=zlib-devel

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget -O $P-$V.tar.gz https://sourceforge.net/projects/libpng/files/libpng16/$V/$P-$V.tar.gz/download
[ -f ../CMakeLists.txt ] || tar -C .. -xzf  $P-$V.tar.gz --xform "s,^$P-$V,.,"

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

vs2019env
cmakeenv
ninjaenv

mkdir -p build
cd build

cmake -G Ninja \
	-D CMAKE_BUILD_TYPE=Release \
	-D ZLIB_LIBRARY=$(cygpath -am ../osgeo4w/lib/zlib.lib) \
	-D ZLIB_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D CMAKE_INSTALL_PREFIX=../install \
	../..
ninja
ninja install

cd ..

cat <<EOF >$R/setup.hint
sdesc: "the official PNG reference library (Runtime)"
ldesc: "the official PNG reference library (Runtime)"
category: Libs
requires: msvcrt2019
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 bin/libpng16.dll

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "the official PNG reference library (Development)"
ldesc: "the official PNG reference library (Development)"
category: Libs
requires: $P
external-source: $P
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	bin/png-fix-itxt.exe \
	bin/pngfix.exe \
	include \
	lib \
	share

cp ../LICENSE $R/$P-$V-$B.txt
cp ../LICENSE $R/$P-devel/$P-devel-$P-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
