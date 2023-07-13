export P=curl
export V=8.1.2
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="openssl-devel zlib-devel"

export VC=15
export VCARCH=x64

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget https://curl.haxx.se/download/$P-$V.tar.gz
[ -f ../$P-$V/CMakeLists.txt ] || tar -C .. -xzf $P-$V.tar.gz

wget -O curl-ca-bundle.crt https://curl.se/ca/cacert.pem

vs2019env

cd ../$P-$V/winbuild
export INCLUDE="$INCLUDE;$(cygpath -aw ../../osgeo4w/osgeo4w/include)"
export LIB="$LIB;$(cygpath -aw ../../osgeo4w/osgeo4w/lib)"
nmake /f Makefile.vc mode=dll VC=$VC WITH_SSL=dll WITH_ZLIB=dll GEN_PDB=yes DEBUG=no MACHINE=$VCARCH WITH_DEVEL="$(cygpath -aw ../../osgeo4w/osgeo4w)"

cd ../../osgeo4w

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-{devel,ca-bundle}

cat <<EOF >$R/setup.hint
sdesc: "The CURL HTTP/FTP library and commandline utility (Runtime)"
ldesc: "The CURL HTTP/FTP library and commandline utility (Runtime)"
category: Libs Commandline_Utilities
requires: msvcrt2019 openssl $P-ca-bundle zlib
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

tar -C ../$P-$V/builds/libcurl-vc$VC-$VCARCH-release-dll-ssl-dll-zlib-dll-ipv6-sspi \
	-cjf $R/$P-$V-$B.tar.bz2 \
	--exclude bin/curl.pdb \
	bin

tar -C ../$P-$V/builds/libcurl-vc$VC-$VCARCH-release-dll-ssl-dll-zlib-dll-ipv6-sspi \
	-cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	bin/curl.pdb \
	include lib

tar -cjf $R/$P-ca-bundle/$P-ca-bundle-$V-$B.tar.bz2 \
	--xform "s,curl-ca-bundle.crt,bin/curl-ca-bundle.crt," \
	curl-ca-bundle.crt

cp ../$P-$V/COPYING $R/$P-$V-$B.txt
cp ../$P-$V/COPYING $R/$P-devel/$P-devel-$P-$V-$B.txt
cp ../$P-$V/COPYING $R/$P-ca-bundle/$P-ca-bundle-$P-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
