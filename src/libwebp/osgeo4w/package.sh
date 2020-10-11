export P=libwebp
export V=1.1.0
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="libtiff-devel libpng-devel libjpeg-devel libtiff-devel zlib-devel"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget https://storage.googleapis.com/downloads.webmproject.org/releases/webp/$P-$V.tar.gz
[ -f ../CMakeLists.txt ] || tar -C .. -xzf $P-$V.tar.gz --xform "s,^$P-$V,.,"

vs2019env
cmakeenv
ninjaenv

mkdir -p build
cd build

cmake -G Ninja \
	-D CMAKE_BUILD_TYPE=Release \
	-D CMAKE_INSTALL_PREFIX=../install \
	-D BUILD_SHARED_LIBS=ON \
	-D ZLIB_LIBRARY=$(cygpath -am ../osgeo4w/lib/zlib.lib) \
	-D ZLIB_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D PNG_LIBRARY=$(cygpath -am ../osgeo4w/lib/libpng16.lib) \
	-D PNG_PNG_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D JPEG_LIBRARY=$(cygpath -am ../osgeo4w/lib/jpeg_i.lib) \
	-D JPEG_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D TIFF_LIBRARY=$(cygpath -am ../osgeo4w/lib/tiff.lib) \
	-D TIFF_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	../..
ninja
ninja install

cd ..

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-{devel,tools}

cat <<EOF >$R/setup.hint
sdesc: "WebP is a modern image format that provides superior lossless and lossy compression. (Runtime)"
ldesc: "WebP is a modern image format that provides superior lossless and lossy compression. (Runtime)"
category: Libs
requires: msvcrt2019 libtiff zlib libpng libjpeg
maintainer: $MAINTAINER
EOF

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "WebP is a modern image format that provides superior lossless and lossy compression. (Development)"
ldesc: "WebP is a modern image format that provides superior lossless and lossy compression. (Development)"
category: Libs
requires: $P
external-source: $P
maintainer: $MAINTAINER
EOF

cat <<EOF >$R/$P-tools/setup.hint
sdesc: "WebP is a modern image format that provides superior lossless and lossy compression. (Tools)"
ldesc: "WebP is a modern image format that provides superior lossless and lossy compression. (Tools)"
category: Libs
requires: $P
external-source: $P
maintainer: $MAINTAINER
EOF

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	--exclude "*.exe" \
	bin

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	--exclude "share/man/man1" \
	include \
	lib \
	share

tar -C install -cjf $R/$P-tools/$P-tools-$V-$B.tar.bz2 \
	--exclude "*.dll" \
	share/man/man1 \
	bin

cp ../COPYING $R/$P-$V-$B.txt
cp ../COPYING $R/$P-devel/$P-devel-$V-$B.txt
cp ../COPYING $R/$P-tools/$P-tools-$V-$B.txt
		

endlog
