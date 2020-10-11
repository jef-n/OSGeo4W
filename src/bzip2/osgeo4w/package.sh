export P=bzip2
export V=1.0.8
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget https://sourceware.org/pub/$P/$P-$V.tar.gz
[ -f ../Makefile ] || tar -C .. -xzf  $P-$V.tar.gz --xform "s,^$P-$V,.,"

vs2019env

cd ..

nmake /f makefile.msc

P=$P-devel

R=$OSGEO4W_REP/x86_64/release/$P

mkdir -p $R

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

tar -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
