export P=libspatialite
export V=5.0.0
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="sqlite3-devel libiconv-devel geos-devel proj-devel freexl-devel libxml2-devel librttopo-devel zlib-devel"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget http://www.gaia-gis.it/gaia-sins/$P-$V.tar.gz
[ -f ../makefile.vc ] || tar -C .. -xzf  $P-$V.tar.gz --xform "s,^$P-$V,.,"

vs2019env

mkdir -p install

cp makefile.vc ..

cd ..

nmake /f makefile.vc OSGEO4W_ROOT=$(cygpath -aw osgeo4w/osgeo4w)
nmake /f makefile.vc OSGEO4W_ROOT=$(cygpath -aw osgeo4w/osgeo4w) INSTDIR=$(cygpath -aw osgeo4w/install) install

cd osgeo4w

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "The SpatiaLite library for adding spatial capabilities to SQLite3 DBMS. (Runtime)"
ldesc: "The SpatiaLite library for adding spatial capabilities to SQLite3 DBMS. (Runtime)"
category: Libs
requires: msvcrt2019 sqlite3 libiconv geos proj freexl libxml2 librttopo zlib
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 bin

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "The SpatiaLite library for adding spatial capabilities to SQLite3 DBMS. (Development)"
ldesc: "The SpatiaLite library for adding spatial capabilities to SQLite3 DBMS. (Development)"
category: Libs
requires: $P
maintainer: $MAINTAINER
external-source: $P
EOF

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	include \
	lib/spatialite.lib \
	lib/spatialite_i.lib

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh osgeo4w/makefile.vc

cp ../COPYING $R//$P-$V-$B.txt
cp ../COPYING $R/$P-devel/$P-devel-$V-$B.txt

endlog
