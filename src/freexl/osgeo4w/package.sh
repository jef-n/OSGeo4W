export P=freexl
export V=2.0.0
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="libiconv-devel zlib-devel minizip-ng-devel expat-devel xz-devel bzip2-devel"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget http://www.gaia-gis.it/gaia-sins/$P-$V.tar.gz
[ -f ../$P-$V/configure ] || tar -C .. -xzf  $P-$V.tar.gz
[ -f ../$P-$V/patched ] || {
        patch -d ../$P-$V -p1 --dry-run <../osgeo4w/patch
        patch -d ../$P-$V -p1 <../osgeo4w/patch
        touch ../$P-$V/patched
}

vs2019env

cd ../$P-$V

OSGEO4W_ROOT=$(cygpath -aw ../osgeo4w/osgeo4w) nmake /f makefile.vc INSTDIR=..\\osgeo4w\\install all install

cd ../osgeo4w

R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cp ../$P-$V/COPYING $R/$P-$V-$B.txt
cp ../$P-$V/COPYING $R/$P-devel/$P-devel-$V-$B.txt

cat <<EOF >$R/setup.hint
sdesc: "The FreeXL library for accessing Excel (.xls) spreadsheet. (Runtime)"
ldesc: "The FreeXL library for accessing Excel (.xls) spreadsheet. (Runtime)"
maintainer: $MAINTAINER
category: Libs
requires: zlib xz expat libiconv msvcrt2019
EOF

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "The FreeXL library for accessing Excel (.xls) spreadsheet. (Development)"
ldesc: "The FreeXL library for accessing Excel (.xls) spreadsheet. (Development)"
maintainer: $MAINTAINER
category: Libs
requires: $P
external-source: $P
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 bin/freexl.dll
tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 include lib
tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh osgeo4w/patch

endlog
