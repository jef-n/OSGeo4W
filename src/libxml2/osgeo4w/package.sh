export P=libxml2
export V=2.9.10
export B=next
export MAINTAINER=JuergenFischer

source ../../../scripts/build-helpers

startlog

fetchdeps zlib-devel libiconv-devel xz-devel
cp -uv osgeo4w/lib/iconv.dll.lib osgeo4w/lib/iconv.lib

[ -f $P-$V.tar.gz ] || wget -c ftp://xmlsoft.org/$P/$P-$V.tar.gz
[ -f ../CMakeLists.txt ] || tar -C .. -xzf  $P-$V.tar.gz --xform "s,^$P-$V,.,"

vs2019env

mkdir -p install

cd ../win32
cscript configure.js compiler=msvc prefix=$(cygpath -w ../osgeo4w/install) iconv=yes zlib=yes lzma=yes include=$(cygpath -aw ../osgeo4w/osgeo4w/include) lib=$(cygpath -aw ../osgeo4w/osgeo4w/lib)

nmake /f Makefile.msvc
touch bin.msvc/ignore.pdb
nmake /f Makefile.msvc install

cd ../osgeo4w

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "An XML read/write library (Runtime)"
ldesc: "An XML read/write library (Runtime)"
category: Libs
requires: msvcrt2019 libiconv zlib xz
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	bin/libxml2.dll \
	bin/xmlcatalog.exe \
	bin/xmllint.exe

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "An XML read/write library (Development)"
ldesc: "An XML read/write library (Development)"
category: Libs
requires: $P
external-source: $P
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	include \
	lib/libxml2.lib \
	lib/libxml2_a.lib \
	lib/libxml2_a_dll.lib

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 \
	osgeo4w/package.sh

cp ../COPYING $R/$P-$V-$B.txt 
cp ../COPYING $R/$P-devel/$P-devel-$V-$B.txt 

endlog
