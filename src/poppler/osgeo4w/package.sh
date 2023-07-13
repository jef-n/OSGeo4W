export P=poppler
export V=23.07.0
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="freetype-devel libjpeg-turbo-devel zlib-devel libpng-devel libtiff-devel curl-devel boost-devel cairo-devel libiconv-devel openjpeg-devel openjpeg-tools"

set -x

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.xz ] || wget https://poppler.freedesktop.org/$P-$V.tar.xz
[ -f ../$P-$V/CMakeLists.txt ] || tar -C .. -xJf $P-$V.tar.xz
[ -f ../$P-$V/patched ] || {
	patch -d ../$P-$V -p1 --dry-run <diff
	patch -d ../$P-$V -p1 <diff
	touch ../$P-$V/patched
}

# should be fixed in openjpeg-devel…
sed -i -e "s#set(INC_DIR .*)#set(INC_DIR \"$(cygpath -am osgeo4w/include/openjpeg-2.4)\")#i" osgeo4w/lib/openjpeg-2.4/OpenJPEGConfig.cmake

[ -f poppler-test.tar.gz ] || wget -O poppler-test.tar.gz https://github.com/freedesktop/poppler-test/archive/refs/heads/master.tar.gz
[ -d poppler-test-master ] || tar xzf poppler-test.tar.gz

p=$P-data
v=0.4.11
[ -f $p-$v.tar.gz ] || wget https://poppler.freedesktop.org/$p-$v.tar.gz
[ -d $p ] || tar -xzf $p-$v.tar.gz --xform "s,^$p-$v,$p,"

cmakeenv
ninjaenv

mkdir -p install

if ! [ -f poppler-data.done ]; then
	cd poppler-data
	make install datadir=/share DESTDIR=../install
	cd ..
	touch poppler-data.done
fi

vs2019env

mkdir -p build
cd build

# ENABLE_UNSTABLE_API_ABI_HEADERS for private headers

PATH=$(echo $PATH | sed -e "s,:/bin,,g" -e "s,:/usr/bin,,g") \
cmake -G Ninja \
	-D CMAKE_BUILD_TYPE=Release \
	-D CMAKE_INSTALL_PREFIX=../install \
	-D BUILD_GTK_TESTS=OFF \
	-D BUILD_QT5_TESTS=OFF \
	-D BUILD_QT6_TESTS=OFF \
	-D BUILD_CPP_TESTS=OFF \
	-D ENABLE_UTILS=ON \
	-D ENABLE_CPP=OFF \
	-D ENABLE_QT5=OFF \
	-D ENABLE_QT6=OFF \
	-D ENABLE_GLIB=OFF \
	-D WITH_NSS3=OFF \
	-D ENABLE_RELOCATABLE=OFF \
	-D ENABLE_UNSTABLE_API_ABI_HEADERS=ON \
	-D OpenJPEG_DIR=$(cygpath -am ../osgeo4w/lib/openjpeg-2.4) \
	-D FREETYPE_INCLUDE_DIRS=$(cygpath -am ../osgeo4w/include/freetype2) \
	-D FREETYPE_LIBRARY=$(cygpath -am ../osgeo4w/lib/freetype.lib) \
        -D ZLIB_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
        -D ZLIB_LIBRARY=$(cygpath -am ../osgeo4w/lib/zlib.lib) \
        -D PNG_PNG_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
        -D PNG_LIBRARY=$(cygpath -am ../osgeo4w/lib/libpng16.lib) \
        -D TIFF_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
        -D TIFF_LIBRARY=$(cygpath -am ../osgeo4w/lib/tiff.lib) \
        -D JPEG_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
        -D JPEG_LIBRARY=$(cygpath -am ../osgeo4w/lib/jpeg.lib) \
        -D CURL_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
        -D CURL_LIBRARY=$(cygpath -am ../osgeo4w/lib/libcurl.lib) \
	-D Boost_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include/boost-1_74) \
        -D CAIRO_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
        -D CAIRO_LIBRARY=$(cygpath -am ../osgeo4w/lib/cairo.lib) \
        -D ICONV_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
        -D ICONV_LIBRARIES=$(cygpath -am ../osgeo4w/lib/iconv.dll.lib) \
	-D TESTDATADIR=$(cygpath -am ../poppler-test-master) \
	../../$P-$V
ninja
ninja install
cd ..

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-{devel,tools}

cat <<EOF >$R/setup.hint
sdesc: "Poppler is a PDF rendering library based on the xpdf-3.0 code base. (Runtime)"
ldesc: "Poppler is a PDF rendering library based on the xpdf-3.0 code base. (Runtime)"
category: Libs
requires: msvcrt2019 freetype zlib libpng libtiff libjpeg-turbo cairo
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	--exclude "*.exe" \
	bin

cat <<EOF >$R/$P-tools/setup.hint
sdesc: "Poppler is a PDF rendering library based on the xpdf-3.0 code base. (Tools)"
ldesc: "Poppler is a PDF rendering library based on the xpdf-3.0 code base. (Tools)"
category: Commandline_Utilities
requires: $P
external-source: $P
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-tools/$P-tools-$V-$B.tar.bz2 \
	--exclude "*.dll" \
	share/man \
	bin

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "Poppler is a PDF rendering library based on the xpdf-3.0 code base. (Development)"
ldesc: "Poppler is a PDF rendering library based on the xpdf-3.0 code base. (Development)"
category: Libs
requires: $P
external-source: $P
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	lib \
	include

cp ../$P-$V/COPYING $R/$P-$V-$B.txt
cp ../$P-$V/COPYING $R/$P-tools/$P-tools-$V-$B.txt
cp ../$P-$V/COPYING $R/$P-devel/$P-devel-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh osgeo4w/diff

endlog
