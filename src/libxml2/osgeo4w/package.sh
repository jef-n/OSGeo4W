export P=libxml2
export V=2.12.5
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="zlib-devel libiconv-devel xz-devel"
export PACKAGES="libxml2 libxml2-devel"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.xz ] || wget -c https://download.gnome.org/sources/$P/${V%.*}/$P-$V.tar.xz
[ -f ../$P-$V/CMakeLists.txt ] || tar -C .. -xJf $P-$V.tar.xz

vsenv
cmakeenv
ninjaenv

mkdir -p install build

cd build

export LIB="$(cygpath -aw ../osgeo4w/lib);$LIB"
export INCLUDE="$(cygpath -aw ../osgeo4w/include);$INCLUDE"

cmake -G Ninja \
	-D CMAKE_BUILD_TYPE=Release \
	-D CMAKE_INSTALL_PREFIX=../install \
	-D ZLIB_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D ZLIB_LIBRARY=$(cygpath -am ../osgeo4w/lib/zlib.lib) \
	-D LZMA_LIBRARY=$(cygpath -am ../osgeo4w/lib/liblzma.lib) \
	-D Iconv_LIBRARY=$(cygpath -am ../osgeo4w/lib/iconv.dll.lib) \
	-D LIBLZMA_LIBRARY_DEBUG=none \
	-D LIBXML2_WITH_PYTHON=OFF \
	../../$P-$V
cmake --build .
cmake --build . --target install
cmakefix ../install

cd ..

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "An XML read/write library (Runtime)"
ldesc: "An XML read/write library (Runtime)"
category: Libs
requires: msvcrt2019 libiconv zlib xz
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	bin/libxml2.dll \
	bin/xmlcatalog.exe \
	bin/xmllint.exe

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "An XML read/write library (Development)"
ldesc: "An XML read/write library (Development)"
category: Libs
requires: $P libiconv-devel
external-source: $P
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	include lib

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 \
	osgeo4w/package.sh

cp ../$P-$V/Copyright $R/$P-$V-$B.txt
cp ../$P-$V/Copyright $R/$P-devel/$P-devel-$V-$B.txt

endlog
