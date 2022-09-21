export P=wxwidgets
export V=3.2.1
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="zlib-devel expat-devel libjpeg-turbo-devel libpng-devel libtiff-devel xz-devel"


source ../../../scripts/build-helpers

startlog

[ -d ../$P-$V ] || git clone --recurse-submodules https://github.com/wxWidgets/wxWidgets --branch v$V --single-branch ../$P-$V

vs2019env
cmakeenv
ninjaenv

mkdir -p build install
cd build

cmake -G Ninja \
	-D CMAKE_BUILD_TYPE=Release \
	-D CMAKE_INSTALL_PREFIX=../install \
	-D wxBUILD_VENDOR=osgeo4w \
	-D wxUSE_ZLIB=sys    -D    ZLIB_LIBRARY=$(cygpath -am ../osgeo4w/lib/zlib.lib)     -D    ZLIB_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D wxUSE_EXPAT=sys   -D   EXPAT_LIBRARY=$(cygpath -am ../osgeo4w/lib/libexpat.lib) -D   EXPAT_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D wxUSE_LIBJPEG=sys -D    JPEG_LIBRARY=$(cygpath -am ../osgeo4w/lib/jpeg.lib)     -D    JPEG_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D wxUSE_LIBPNG=sys  -D     PNG_LIBRARY=$(cygpath -am ../osgeo4w/lib/libpng16.lib) -D PNG_PNG_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D wxUSE_LIBTIFF=sys -D    TIFF_LIBRARY=$(cygpath -am ../osgeo4w/lib/tiff.lib)     -D    TIFF_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D wxUSE_LIBLZMA=sys -D LIBLZMA_LIBRARY=$(cygpath -am ../osgeo4w/lib/liblzma.lib)  -D LIBLZMA_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	../../$P-$V
cmake --build .
cmake --install .

cd ..

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-{devel,tools}

cat <<EOF >$R/setup.hint
sdesc: "cross-platform GUI library (runtime)"
ldesc: "cross-platform GUI library (runtime)"
category: Libs
requires: msvcrt2019 zlib expat libjpeg-turbo libpng libtiff xz
maintainer: $MAINTAINER
EOF

tar -cjf $R/$P-$V-$B.tar.bz2 \
	--xform "s,^install/lib/vc_x64_dll/,bin/," \
	install/lib/vc_x64_dll/*.dll

cat <<EOF >$R/$P-tools/setup.hint
sdesc: "cross-platform GUI library (tools)"
ldesc: "cross-platform GUI library (tools)"
category: Commandline_Utilities
requires: $P
maintainer: $MAINTAINER
external-source: $P
EOF

tar -C install -cjf $R/$P-tools/$P-tools-$V-$B.tar.bz2 \
	bin

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "cross-platform GUI library (development)"
ldesc: "cross-platform GUI library (development)"
category: Libs
requires: $P
maintainer: $MAINTAINER
external-source: $P
EOF

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	--exclude "*.dll" \
	include lib

cp ../$P-$V/docs/licence.txt $R/$P-$V-$B.txt
cp ../$P-$V/docs/licence.txt $R/$P-tools/$P-tools-$V-$B.txt
cp ../$P-$V/docs/licence.txt $R/$P-devel/$P-devel-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
