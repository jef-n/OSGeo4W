export P=bzip2-devel
export V=1.0.8
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none
export PACKAGES="bzip2-devel"

source ../../../scripts/build-helpers

startlog

p=${P%-devel}
[ -f $p-$V.tar.gz ] || wget https://sourceware.org/pub/$p/$p-$V.tar.gz
[ -f ../$p-$V/Makefile ] || tar -C .. -xzf $p-$V.tar.gz

vsenv

cd ../$p-$V

nmake /f makefile.msc

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R

tar -cjf $R/$P-$V-$B.tar.bz2 \
	--xform "s,libbz2.lib,lib/libbz2.lib," \
	--xform "s,bzlib.h,include/bzlib.h," \
	bzlib.h \
	libbz2.lib

cat <<EOF >$R/setup.hint
sdesc: "The bzip2 compression and decompression library (development)"
sdesc: "The bzip2 compression and decompression library (development)"
category: Libs
requires: $P
maintainer: $MAINTAINER
EOF

cp LICENSE $R/$P-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
