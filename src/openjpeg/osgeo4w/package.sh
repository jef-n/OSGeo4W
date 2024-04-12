export P=openjpeg
export V=2.5.2
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="zlib-devel libtiff-devel libpng-devel"
export PACKAGES="openjpeg openjpeg-devel openjpeg-tools"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget -O $P-$V.tar.gz https://github.com/uclouvain/$P/archive/v$V.tar.gz
[ -f ../$P-$V/CMakeLists.txt ] || tar -C .. -xzf $P-$V.tar.gz

vsenv
cmakeenv
ninjaenv

mkdir -p build{,-lcms2} install

cd build-lcms2

cmake -G Ninja \
	-Wno-dev \
	../../$P-$V/thirdparty/liblcms2
ninja

cd ../build
cmake -G Ninja \
	-Wno-dev \
	-D CMAKE_BUILD_TYPE=Release \
	-D CMAKE_INSTALL_PREFIX=../install \
	-D BUILD_CODEC=ON \
	-D BUILD_JPIP=ON \
	-D BUILD_JPIP_SERVER=OFF \
	-D BUILD_JAVA=OFF \
	-D BUILD_MJ2=OFF \
	-D BUILD_JP3D=ON \
	-D BUILD_SHARED_LIBS=ON \
	-D BUILD_STATIC_LIBS=OFF \
	-D BUILD_TESTING=OFF \
	-D BUILD_DOC=OFF \
	-D BUILD_THIRDPARTY=OFF \
	-D PNG_PNG_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D PNG_LIBRARY=$(cygpath -am ../osgeo4w/lib/libpng16.lib) \
	-D ZLIB_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D ZLIB_LIBRARY=$(cygpath -am ../osgeo4w/lib/zlib.lib) \
	-D TIFF_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D TIFF_LIBRARY=$(cygpath -am ../osgeo4w/lib/tiff.lib) \
	../../$P-$V
ninja
ninja install
cmakefix ../install

cd ..

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-{tools,devel}

cat <<EOF >$R/setup.hint
sdesc: "OpenJPEG (runtime)"
ldesc: "OpenJPEG : Open source C-Library for JPEG2000"
category: Libs
requires: msvcrt2019 libtiff zlib libpng
maintainer: $MAINTAINER
EOF

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "OpenJPEG (development)"
ldesc: "OpenJPEG : Open source C-Library for JPEG2000"
category: Libs
requires: $P
external-source: $P
maintainer: $MAINTAINER
EOF

cat <<EOF >$R/$P-tools/setup.hint
sdesc: "OpenJPEG (tools)"
ldesc: "OpenJPEG : Open source C-Library for JPEG2000"
category: Libs
requires: $P
external-source: $P
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	bin/openjpip.dll \
	bin/openjp2.dll

tar -C install -cjf $R/$P-tools/$P-tools-$V-$B.tar.bz2 \
	--exclude "bin/*.dll" \
	bin

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	include lib

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 \
	osgeo4w/package.sh

cp ../$P-$V/LICENSE $R/$P-$V-$B.txt
cp ../$P-$V/LICENSE $R/$P-devel/$P-devel-$V-$B.txt
cp ../$P-$V/LICENSE $R/$P-tools/$P-tools-$V-$B.txt

endlog
