export P=fcgi
export V=2.4.7
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none
export PACKAGES="fcgi fcgi-devel"

source ../../../scripts/build-helpers

startlog

s=${P}2-$V
[ -f $P-$V.tar.gz ] || wget -O $P-$V.tar.gz https://github.com/FastCGI-Archives/fcgi2/archive/$V.tar.gz
[ -f ../$s/libfcgi ] || tar -C .. -xzf $P-$V.tar.gz
[ -f ../$s/patched ] || {
	patch -d ../$s -p1 --dry-run <patch
	patch -d ../$s -p1 <patch
	touch ../$s/patched
}

vsenv
cmakeenv
ninjaenv

cd ../$s/libfcgi
nmake /f libfcgi.mak

cd ../../osgeo4w

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "FastCGI Library (Runtime)"
ldesc: "FastCGI Library (Runtime)"
maintainer: $MAINTAINER
category: Libs
requires: msvcrt2019
EOF

tar -C ../$s/libfcgi/Release -cjf $R/$P-$V-$B.tar.bz2 \
	--xform "s,libfcgi.dll,bin/libfcgi.dll," \
	libfcgi.dll

cp ../$s/LICENSE $R/$P-$V-$B.txt

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "FastCGI Library (Development)"
ldesc: "FastCGI Library (Development)"
maintainer: $MAINTAINER
category: Libs
requires: $P
external-source: $P
EOF

tar -C ../$s -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	--xform "s,libfcgi/Release/libfcgi.lib,lib/libfcgi.lib," \
	--exclude include/fcgi_config_x86.h \
	--exclude include/fcgi_config.h.in \
	--exclude include/Makefile.am \
	--exclude include/.gitignore \
	libfcgi/Release/libfcgi.lib \
	include

cp ../$s/LICENSE $R/$P-devel/$P-devel-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 \
	osgeo4w/package.sh \
	osgeo4w/patch

endlog
