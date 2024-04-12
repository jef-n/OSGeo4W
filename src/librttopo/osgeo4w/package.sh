export P=librttopo
export V=1.1.0
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=geos-devel
export PACKAGES="librttopo librttopo-devel"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget https://git.osgeo.org/gitea/rttopo/librttopo/archive/$P-$V.tar.gz
[ -f ../$P/makefile.vc ] || tar -C .. -xzf $P-$V.tar.gz
[ -f ../$P/patched ] || {
	patch -d ../$P -p1 --dry-run <patch
	patch -d ../$P -p1 <patch >../$P/patched
}

vsenv

mkdir -p install

cd ../$P

nmake /f makefile.vc OSGEO4W_ROOT=$(cygpath -aw ../osgeo4w/osgeo4w)
nmake /f makefile.vc OSGEO4W_ROOT=$(cygpath -aw ../osgeo4w/osgeo4w) INSTDIR=..\\osgeo4w\\install install

cd ../osgeo4w

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "RT Topology Library (Runtime)"
ldesc: "RT Topology Library (Runtime)"
category: Libs
requires: msvcrt2019 geos
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 bin

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "RT Topology Library (Development)"
ldesc: "RT Topology Library (Development)"
category: Libs
requires: $P
maintainer: $MAINTAINER
external-source: $P
EOF

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 include lib

cp ../$P/COPYING $R/$P-$V-$B.txt
cp ../$P/COPYING $R/$P-devel/$P-devel-$P-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh osgeo4w/patch

endlog
