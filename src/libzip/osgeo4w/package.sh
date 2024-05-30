export P=libzip
export V=1.10.2really1.7.3
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="openssl-devel zlib-devel xz-devel bzip2-devel zstd-devel"
export PACKAGES="libzip libzip-devel libzip-tools"

source ../../../scripts/build-helpers

startlog

VV=1.7.3
[ -f $P-$VV.tar.gz ] || wget https://libzip.org/download/$P-$VV.tar.gz
[ -f ../$P-$VV/CMakeLists.txt ] || tar -C .. -xzf $P-$VV.tar.gz

vsenv
cmakeenv
ninjaenv

mkdir -p build install
cd build

cmake -G Ninja \
	-D CMAKE_BUILD_TYPE=Release \
	-D CMAKE_INSTALL_PREFIX=../install \
	-D ENABLE_LZMA=ON \
	-D ENABLE_ZSTD=ON \
	-D OPENSSL_ROOT_DIR=$(cygpath -am ../osgeo4w) \
	-D OPENSSL_CRYPTO_LIBRARY=$(cygpath -am ../osgeo4w/lib/libcrypto.lib) \
	-D OPENSSL_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include/openssl) \
	-D ZLIB_LIBRARY=$(cygpath -am ../osgeo4w/lib/zlib.lib) \
	-D ZLIB_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D LIBLZMA_LIBRARY=$(cygpath -am ../osgeo4w/lib/liblzma.lib) \
	-D LIBLZMA_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D _zstd_LIBRARY=$(cygpath -am ../osgeo4w/lib/zstd.lib) \
	-D _zstd_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D BZIP2_LIBRARIES=$(cygpath -am ../osgeo4w/lib/libbz2.lib) \
	-D BZIP2_LIBRARY=$(cygpath -am ../osgeo4w/lib/libbz2.lib) \
	-D BZIP2_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	../../$P-$VV
ninja
ninja install
cmakefix ../install

cd ..

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-{devel,tools}

cat <<EOF >$R/setup.hint
sdesc: "libzip (runtime library)"
ldesc: "libzip (runtime library)"
category: Libs
requires: msvcrt2019 zlib xz openssl
maintainer: $MAINTAINER
EOF

cat <<EOF >$R/$P-tools/setup.hint
sdesc: "libzip (executables)"
ldesc: "libzip (executables)"
maintainer: JuergenFischer
category: Commandline_Utilities
requires: $P
external-source: $P
EOF

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "libzip (development)"
ldesc: "libzip (development)"
maintainer: JuergenFischer
category: Libs
requires: $P
external-source: $P
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	--exclude "*.exe" \
	bin

tar -C install -cjf $R/$P-tools/$P-tools-$V-$B.tar.bz2 \
	--exclude "*.dll" \
	bin

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	include \
	lib

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

cp ../$P-$VV/LICENSE $R/$P-$V-$B.txt
cp ../$P-$VV/LICENSE $R/$P-tools/$P-tools-$P-$V-$B.txt
cp ../$P-$VV/LICENSE $R/$P-devel/$P-devel-$P-$V-$B.txt

endlog
