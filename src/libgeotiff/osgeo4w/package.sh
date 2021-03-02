export P=libgeotiff
export V=1.6.0
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="proj-devel libtiff-devel"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget http://download.osgeo.org/geotiff/$P/$P-$V.tar.gz
[ -f ../$P-$V/CMakeLists.txt ] || tar -C .. -xzf $P-$V.tar.gz

vs2019env
cmakeenv
ninjaenv

mkdir -p build
cd build

cmake -G Ninja \
	-D CMAKE_BUILD_TYPE=Release \
	-D CMAKE_INSTALL_PREFIX=../install \
	-D BUILD_SHARED_LIBS=ON \
	-D PROJ_LIBRARY=$(cygpath -am ../osgeo4w/lib/proj.lib) \
	-D PROJ_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D TIFF_LIBRARY=$(cygpath -am ../osgeo4w/lib/tiff.lib) \
	-D TIFF_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D OPENSSL_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include/openssl) \
	-D OPENSSL_CRYPTO_LIBRARY=$(cygpath -am ../osgeo4w/lib/libcrypto.lib) \
	../../$P-$V
ninja
ninja install

cd ..

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "The Libgeotiff library, commandline tools and supporting tables (Runtime)"
ldesc: "The Libgeotiff library, commandline tools and supporting tables (Runtime)"
category: Libs Commandline_Utilities
requires: msvcrt2019 $RUNTIMEDEPENDS libtiff
maintainer: $MAINTAINER
EOF

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "The Libgeotiff library, commandline tools and supporting tables (Development)"
ldesc: "The Libgeotiff library, commandline tools and supporting tables (Development)"
category: Libs
requires: $P
external-source: $P
maintainer: $MAINTAINER
EOF

cp ../$P-$V/COPYING $R/$P-$V-$B.txt

tar -C install -cjf $R/$P-$V-$B.tar.bz2 bin
tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 include lib
tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
