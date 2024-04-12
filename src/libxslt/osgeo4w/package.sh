export P=libxslt
export V=1.1.39
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="zlib-devel libiconv-devel xz-devel libxml2-devel"
export PACKAGES="libxslt libxslt-devel"

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
	-D CMAKE_FIND_DEBUG_MODE=ON \
	-D LIBXSLT_WITH_PYTHON=OFF \
	-D Iconv_LIBRARY=$(cygpath -am ../osgeo4w/lib/iconv.dll.lib) \
	../../$P-$V

cmake --build .
cmake --build . --target install

cd ..

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "XSLT 1.1 processing library (runtime)"
ldesc: "XSLT 1.1 processing library (runtime)"
category: Libs
requires: msvcrt2019 libiconv zlib xz libxml2
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	bin/libexslt.dll \
	bin/libxslt.dll \
	bin/xsltproc.exe

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "XSLT 1.1 processing library (development)"
ldesc: "XSLT 1.1 processing library (development)"
category: Libs
requires: $P libiconv-devel
external-source: $P
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	include lib

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 \
	osgeo4w/package.sh

cp ../$P-$V/COPYING $R/$P-$V-$B.txt
cp ../$P-$V/COPYING $R/$P-devel/$P-devel-$V-$B.txt

endlog
