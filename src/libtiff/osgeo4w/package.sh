export P=libtiff
export V=4.1.0
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="libjpeg-devel libjpeg12-devel xz-devel zlib-devel zstd-devel"	# webp <=> libtiff

source ../../../scripts/build-helpers

startlog

[ -f tiff-$V.tar.gz ] || wget http://download.osgeo.org/$P/tiff-$V.tar.gz
[ -f ../CMakeLists.txt ] || tar -C .. -xzf tiff-$V.tar.gz --xform "s,^tiff-$V,.,"

sed -i -e 's/ @LIBJPEG_12_PATH@/ "@LIBJPEG_12_PATH@"/' ../libtiff/tif_config.h.cmake.in

vs2019env
cmakeenv
ninjaenv

mkdir -p build
cd build

cmake -G Ninja \
	-D CMAKE_BUILD_TYPE=Release \
	-D CMAKE_INSTALL_PREFIX=../install \
	-D JPEG_INCLUDE_DIR=../osgeo4w/include \
	-D JPEG_LIBRARY=$(cygpath -aw ../osgeo4w/lib/jpeg_i.lib) \
	-D JPEG12_INCLUDE_DIR=../osgeo4w/include/libjpeg12 \
	-D JPEG12_LIBRARY=$(cygpath -aw ../osgeo4w/lib/jpeg12_i.lib) \
	-D LIBLZMA_INCLUDE_DIR=../osgeo4w/include \
	-D LIBLZMA_LIBRARY=$(cygpath -aw ../osgeo4w/lib/liblzma.lib) \
	-D ZLIB_INCLUDE_DIR=../osgeo4w/include \
	-D ZLIB_LIBRARY=$(cygpath -aw ../osgeo4w/lib/zlib.lib) \
	-D ZSTD_INCLUDE_DIR=../osgeo4w/include \
	-D ZSTD_LIBRARY=$(cygpath -aw ../osgeo4w/lib/zstd.lib) \
	-D cxx=OFF \
	../..
ninja
ninja install

cd ..

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-{devel,tools}

cat <<EOF >$R/setup.hint
sdesc: "A library for manipulating TIFF format image files (runtime)"
ldesc: "A library for manipulating TIFF format image files (runtime)"
category: Libs
requires: msvcrt2019 libjpeg libjpeg12 zlib xz zstd
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	bin/tiff.dll 

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "A library for manipulating TIFF format image files (development)"
ldesc: "A library for manipulating TIFF format image files (development)"
category: Libs
requires: $P
maintainer: $MAINTAINER
external-source: $P
EOF

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	include \
	lib \
	share

cat <<EOF >$R/$P-tools/setup.hint
sdesc: "A library for manipulating TIFF format image files (tools)"
ldesc: "A library for manipulating TIFF format image files (tools)"
category: Libs
requires: $P
maintainer: $MAINTAINER
external-source: $P
EOF

tar -C install -cjf $R/$P-tools/$P-tools-$V-$B.tar.bz2 \
	--exclude bin/tiff.dll \
	bin

cp ../COPYRIGHT $R/$P-$V-$B.txt
cp ../COPYRIGHT $R/$P-devel/$P-devel-$V-$B.txt
cp ../COPYRIGHT $R/$P-tools/$P-tools-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
