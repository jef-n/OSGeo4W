export P=libtiff
export V=4.7.0
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="libjpeg-turbo-devel xz-devel zlib-devel zstd-devel libwebp-devel lerc-devel"
export PACKAGES="libtiff libtiff-devel libtiff-tools"

source ../../../scripts/build-helpers

startlog

p=${P#lib}
[ -f $p-$V.tar.gz ] || wget http://download.osgeo.org/$P/$p-$V.tar.gz
[ -f ../$p-$V/CMakeLists.txt ] || tar -C .. -xzf $p-$V.tar.gz
[ -f ../$p-$V/patched ] || {
	patch -d ../$p-$V -p1 --dry-run <patch
	patch -d ../$p-$V -p1 <patch >../$p-$V/patched
}

vsenv
cmakeenv
ninjaenv

mkdir -p build
cd build

cmake -G Ninja \
	-D CMAKE_BUILD_TYPE=Release \
	-D CMAKE_INSTALL_PREFIX=../install \
	-D cxx=OFF \
	-D    JPEG_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D        JPEG_LIBRARY=$(cygpath -am ../osgeo4w/lib/jpeg.lib) \
	-D    ZLIB_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D        ZLIB_LIBRARY=$(cygpath -am ../osgeo4w/lib/zlib.lib) \
	-D    ZSTD_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D        ZSTD_LIBRARY=$(cygpath -am ../osgeo4w/lib/zstd.lib) \
	-D    LERC_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D        LERC_LIBRARY=$(cygpath -am ../osgeo4w/lib/lerc.lib) \
	-D    WebP_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D        WebP_LIBRARY=$(cygpath -am ../osgeo4w/lib/libwebp.lib) \
	-D lzma=ON \
	-D LIBLZMA_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D     LIBLZMA_LIBRARY=$(cygpath -am ../osgeo4w/lib/liblzma.lib) \
	../../$p-$V
cmake --build .
cmake --install . || cmake --install .
cmakefix ../install

cd ..

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-{devel,tools}

cat <<EOF >$R/setup.hint
sdesc: "A library for manipulating TIFF format image files (runtime)"
ldesc: "A library for manipulating TIFF format image files (runtime)"
category: Libs
requires: msvcrt2019 libjpeg-turbo zlib zstd lerc libwebp xz
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
category: Commandline_Utilities
requires: $P
maintainer: $MAINTAINER
external-source: $P
EOF

tar -C install -cjf $R/$P-tools/$P-tools-$V-$B.tar.bz2 \
	--exclude bin/tiff.dll \
	bin

cp ../tiff-$V/LICENSE.md $R/$P-$V-$B.txt
cp ../tiff-$V/LICENSE.md $R/$P-devel/$P-devel-$V-$B.txt
cp ../tiff-$V/LICENSE.md $R/$P-tools/$P-tools-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh osgeo4w/patch

endlog
