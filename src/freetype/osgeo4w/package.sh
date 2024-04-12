export P=freetype
export V=2.13.2
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="libpng-devel zlib-devel"
export PACKAGES="freetype freetype-devel"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget https://download.savannah.gnu.org/releases/$P/$P-$V.tar.gz
[ -f ../$P-$V/CMakeLists.txt ] || tar -C .. -xzf $P-$V.tar.gz

vsenv
cmakeenv
ninjaenv

mkdir -p build
cd build

cmake -G Ninja \
	-D CMAKE_BUILD_TYPE=Release \
	-D BUILD_SHARED_LIBS=true \
	-D FT_WITH_ZLIB=ON \
	-D FT_WITH_PNG=ON \
	-D FT_WITH_BROTLI=OFF \
	-D FT_WITH_BZIP2=OFF \
	-D FT_WITH_HARFBUZZ=OFF \
	-D ZLIB_LIBRARY=$(cygpath -am ../osgeo4w/lib/zlib.lib) \
	-D ZLIB_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D PNG_LIBRARY=$(cygpath -am ../osgeo4w/lib/libpng16.lib) \
	-D PNG_PNG_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D CMAKE_INSTALL_PREFIX=../install \
	../../$P-$V
ninja
ninja install

cd ..

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "FreeType library (Runtime)."
ldesc: "FreeType library (Runtime)."
category: Libs
requires: msvcrt2019
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 bin/freetype.dll

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "The zlib compression and decompression library (development)"
ldesc: "The zlib compression library provides in-memory compression and
decompression functions, including integrity checks of the uncompressed
data.  This version of the library supports only one compression method
(deflation), but other algorithms may be added later, which will have
the same stream interface.  The zlib library is used by many different
system programs."
category: Libs
requires: $P
maintainer: $MAINTAINER
external-source: $P
EOF

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	include \
	lib

cp ../$P-$V/LICENSE.TXT $R/$P-$V-$B.txt
cp ../$P-$V/LICENSE.TXT $R/$P-devel/$P-devel-$P-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
