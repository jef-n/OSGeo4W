export P=libxslt
export V=1.1.34
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="zlib-devel libiconv-devel libxml2-devel"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget -c ftp://xmlsoft.org/$P/$P-$V.tar.gz
[ -f ../win32/configure.js ] || tar -C .. -xzf  $P-$V.tar.gz --xform "s,^$P-$V,.,"
[ -f patched ] || {
	patch -d.. -p1 --dry-run <patch
	patch -d.. -p1 <patch
	touch patched
}

vs2019env

mkdir -p install

cd ../win32
cscript configure.js \
	compiler=msvc \
	prefix=$(cygpath -w ../osgeo4w/install) \
	iconv=yes \
	zlib=yes \
	include="$(cygpath -aw ../osgeo4w/osgeo4w/include/libxml2);$(cygpath -aw ../osgeo4w/osgeo4w/include)" \
	lib=$(cygpath -aw ../osgeo4w/osgeo4w/lib)

nmake /f Makefile.msvc
nmake /f Makefile.msvc install

cd ../osgeo4w

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "XSLT 1.1 processing library (runtime)"
ldesc: "XSLT 1.1 processing library (runtime)"
category: Libs
requires: msvcrt2019 libiconv zlib libxml2
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	bin/libexslt.dll \
	bin/libxslt.dll \
	bin/xsltproc.exe

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "XSLT 1.1 processing library (development)"
ldesc: "XSLT 1.1 processing library (development)"
category: Libs
requires: $P libiconv-devel
external-source: $P
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	include \
	lib

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 \
	osgeo4w/package.sh osgeo4w/patch

cp ../COPYING $R/$P-$V-$B.txt 
cp ../COPYING $R/$P-devel/$P-devel-$V-$B.txt 

endlog
