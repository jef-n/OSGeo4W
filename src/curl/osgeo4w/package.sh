export P=curl
export V=8.14.1
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="openssl-devel zlib-devel brotli-devel zstd-devel"
export PACKAGES="curl curl-ca-bundle curl-devel"

export VC=15
export VCARCH=x64

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget https://curl.haxx.se/download/$P-$V.tar.gz
[ -f ../$P-$V/CMakeLists.txt ] || tar -C .. -xzf $P-$V.tar.gz
[ -f ../$P-$V/patched ] || {
	patch -d ../$P-$V -p1 --dry-run <patch
	patch -d ../$P-$V -p1 <patch >../$P-$V/patched
}

wget -O curl-ca-bundle.crt https://curl.se/ca/cacert.pem

cmakeenv
ninjaenv
vsenv

export INCLUDE="$INCLUDE;$(cygpath -aw osgeo4w/include)"
export LIB="$LIB;$(cygpath -aw osgeo4w/lib)"

rm -rf build install
mkdir -p build install
cd build

cmake -G Ninja \
	-D CMAKE_BUILD_TYPE=Release \
	-D CMAKE_SHARED_LINKER_FLAGS=/Fd \
	-D CMAKE_INSTALL_PREFIX=$(cygpath -am ../install) \
	-D CURL_USE_OPENSSL=ON \
	-D CURL_USE_LIBPSL=OFF \
	-D CURL_USE_LIBSSH2=OFF \
	-D CURL_USE_SCHANNEL=ON \
	-D USE_WIN32_IDN=ON \
	-D ENABLE_CURL_MANUAL=OFF \
        -D ZSTD_LIBRARY=$(cygpath -am ../osgeo4w/lib/zstd.lib) \
        -D ZSTD_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
        -D BROTLIDEC_LIBRARY=$(cygpath -am ../osgeo4w/lib/brotlidec.lib) \
        -D BROTLICOMMON_LIBRARY=$(cygpath -am ../osgeo4w/lib/brotlicommon.lib) \
        -D BROTLI_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	../../$P-$V

ninja
ninja install

cd ..

cmakefix install

sed -i \
	-e 's#$(cygpath -am install)#${OSGEO4W_ROOT_MSYS}#g' \
	-e 's#$(cygpath -am ../osgeo4w)#${OSGEO4W_ROOT_MSYS}#g;' \
	install/lib/pkgconfig/libcurl.pc \
	install/bin/curl-config

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-{devel,ca-bundle}

cat <<EOF >$R/setup.hint
sdesc: "The CURL HTTP/FTP library and commandline utility (Runtime)"
ldesc: "The CURL HTTP/FTP library and commandline utility (Runtime)"
category: Libs Commandline_Utilities
requires: msvcrt2019 openssl $P-ca-bundle zlib brotli zstd
maintainer: $MAINTAINER
EOF

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "The CURL HTTP/FTP library and commandline utility (Development)"
ldesc: "The CURL HTTP/FTP library and commandline utility (Development)"
category: Libs
requires: $P
maintainer: $MAINTAINER
external-source: $P
EOF

cat <<EOF >$R/$P-ca-bundle/setup.hint
sdesc: "The CURL HTTP/FTP library and commandline utility (certificates)"
ldesc: "The CURL HTTP/FTP library and commandline utility (certificates)"
category: Libs
requires: $P
maintainer: $MAINTAINER
external-source: $P
EOF

tar -cjf $R/$P-$V-$B.tar.bz2 \
	-C install \
	bin/curl.exe \
	bin/libcurl.dll

tar -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	-C install \
	bin/curl-config \
	include \
	lib

tar -cjf $R/$P-ca-bundle/$P-ca-bundle-$V-$B.tar.bz2 \
	--xform "s,curl-ca-bundle.crt,bin/curl-ca-bundle.crt," \
	curl-ca-bundle.crt

cp ../$P-$V/COPYING $R/$P-$V-$B.txt
cp ../$P-$V/COPYING $R/$P-devel/$P-devel-$P-$V-$B.txt
cp ../$P-$V/COPYING $R/$P-ca-bundle/$P-ca-bundle-$P-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh osgeo4w/patch

endlog
