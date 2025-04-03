export P=libarchive
export V=3.7.8
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="zlib-devel bzip2-devel xz-devel lz4-devel zstd-devel"
export PACKAGES="libarchive libarchive-tools libarchive-devel"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.xz ] || wget https://libarchive.org/downloads/$P-$V.tar.xz
[ -f ../$P-$V/CMakeLists.txt ] || tar -C .. -xJf $P-$V.tar.xz

vsenv
cmakeenv
ninjaenv

mkdir -p build install
cd build

cmake -G Ninja \
	-D CMAKE_BUILD_TYPE=Release \
	-D CMAKE_INSTALL_PREFIX=../install \
	-D ZLIB_LIBRARY=$(cygpath -am ../osgeo4w/lib/zlib.lib) \
	-D ZLIB_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D LIBLZMA_LIBRARY=$(cygpath -am ../osgeo4w/lib/liblzma.lib) \
	-D LIBLZMA_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D ZSTD_LIBRARY=$(cygpath -am ../osgeo4w/lib/zstd.lib) \
	-D ZSTD_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D BZIP2_LIBRARIES=$(cygpath -am ../osgeo4w/lib/libbz2.lib) \
	-D BZIP2_LIBRARY=$(cygpath -am ../osgeo4w/lib/libbz2.lib) \
	-D BZIP2_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D LZ4_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D LZ4_LIBRARY=$(cygpath -am ../osgeo4w/lib/lz4.lib) \
	../../$P-$V
ninja
ninja install
cmakefix ../install

cd ..

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-{devel,tools}

cat <<EOF >$R/setup.hint
sdesc: "$P (runtime library)"
ldesc: "$P (runtime library)"
category: Libs
requires: msvcrt2019
maintainer: $MAINTAINER
EOF

cat <<EOF >$R/setup.hint
sdesc: "$P (executables)"
ldesc: "$P (executables)"
category: Commandline_Utilities
requires: $P
maintainer: $MAINTAINER
EOF

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "$P (development)"
ldesc: "$P (development)"
maintainer: $MAINTAINER
category: Libs
requires: $P
external-source: $P
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	bin/archive.dll

tar -C install -cjf $R/$P-tools/$P-tools-$V-$B.tar.bz2 \
	bin/bsdcat.exe \
	bin/bsdcpio.exe \
	bin/bsdtar.exe \
	share

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	include \
	lib

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

cp ../$P-$V/COPYING $R/$P-$V-$B.txt
cp ../$P-$V/COPYING $R/$P-tools/$P-tools-$P-$V-$B.txt
cp ../$P-$V/COPYING $R/$P-devel/$P-devel-$P-$V-$B.txt

endlog
