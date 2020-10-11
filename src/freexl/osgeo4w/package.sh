export P=freexl
export V=1.0.6
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="libiconv-devel"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget http://www.gaia-gis.it/gaia-sins/$P-$V.tar.gz
[ -f ../configure ] || tar -C .. -xzf  $P-$V.tar.gz --xform "s,^$P-$V,.,"

vs2019env

cp makefile.vc ..

cd ..

set -x

OSGEO4W_ROOT=$(cygpath -aw osgeo4w/osgeo4w) nmake /f makefile.vc all

nmake /f makefile.vc INSTDIR=osgeo4w\\install install

cd osgeo4w

R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cp ../COPYING $R/$P-$V-$B.txt
cp ../COPYING $R/$P-devel/$P-devel-$V-$B.txt

cat <<EOF >$R/setup.hint
sdesc: "The FreeXL library for accessing Excel (.xls) spreadsheet. (Runtime)"
ldesc: "The FreeXL library for accessing Excel (.xls) spreadsheet. (Runtime)"
maintainer: $MAINTAINER
category: Libs
requires: libiconv msvcrt2019
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
tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 bin/freexl.dll include lib
tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh osgeo4w/makefile.vc

endlog
