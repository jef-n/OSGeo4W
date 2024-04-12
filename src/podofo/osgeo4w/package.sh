export P=podofo
export V=0.10.3
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="freetype-devel libjpeg-turbo-devel zlib-devel libpng-devel libtiff-devel openssl-devel libxml2-devel"
export PACKAGES="podofo podofo-devel"

set -x

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget -O $P-$V.tar.gz https://github.com/$P/$P/archive/refs/tags/$V.tar.gz
[ -f ../$P-$V/CMakeLists.txt ] || tar -C .. -xzf $P-$V.tar.gz

cmakeenv
ninjaenv
vsenv

mkdir -p build
cd build

cmake -G Ninja \
	-D CMAKE_BUILD_TYPE=Release \
	-D CMAKE_INSTALL_PREFIX=../install \
	-D ZLIB_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D JPEG_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D TIFF_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D LIBXML2_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include/libxml2) \
	-D FREETYPE_INCLUDE_DIRS=$(cygpath -am ../osgeo4w/include/freetype2) \
	-D PNG_PNG_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D ZLIB_LIBRARY=$(cygpath -am ../osgeo4w/lib/zlib.lib) \
	-D JPEG_LIBRARY=$(cygpath -am ../osgeo4w/lib/jpeg.lib) \
	-D TIFF_LIBRARY=$(cygpath -am ../osgeo4w/lib/tiff.lib) \
	-D PNG_LIBRARY=$(cygpath -am ../osgeo4w/lib/libpng16.lib) \
	-D FREETYPE_LIBRARY=$(cygpath -am ../osgeo4w/lib/freetype.lib) \
	-D LIBXML2_LIBRARY=$(cygpath -am ../osgeo4w/lib/libxml2.lib) \
	-D OPENSSL_ROOT_DIR=$(cygpath -am ../osgeo4w) \
	../../$P-$V
ninja
ninja install
cmakefix ../install

cd ..

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "PoDoFo is a s a free portable C++ library to work with the PDF file format. (Runtime)"
ldesc: "PoDoFo is a s a free portable C++ library to work with the PDF file format. (Runtime)"
category: Libs
requires: msvcrt2019 freetype zlib libpng libtiff libjpeg-turbo libxml2 openssl
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	bin

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "PoDoFo is a s a free portable C++ library to work with the PDF file format. (Development)"
ldesc: "PoDoFo is a s a free portable C++ library to work with the PDF file format. (Development)"
category: Libs
requires: $P
external-source: $P
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	lib \
	include \
	share

cp ../$P-$V/COPYING $R/$P-$V-$B.txt
cp ../$P-$V/COPYING $R/$P-devel/$P-devel-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog

exit 0
