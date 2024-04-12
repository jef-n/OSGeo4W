export P=cairo
export V=1.17.2
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="zlib-devel libpng-devel freetype-devel"
export PACKAGES="cairo cairo-devel"

source ../../../scripts/build-helpers

startlog

cp osgeo4w/lib/zlib.lib osgeo4w/lib/zdll.lib
cp osgeo4w/lib/libpng16.lib osgeo4w/lib/libpng.lib

pixman=pixman-0.42.2

[ -f $P-$V.tar.xz ] || wget https://cairographics.org/snapshots/$P-$V.tar.xz
[ -f ../$P-$V/Makefile.win32 ] || tar -C .. -xJf $P-$V.tar.xz

[ -f $pixman.tar.gz ] || wget https://www.cairographics.org/releases/$pixman.tar.gz
[ -f ../$P-$V/pixman/Makefile.win32 ] || tar -C ../$P-$V -xzf $pixman.tar.gz --xform "s,$pixman,pixman,"

sed -i "s/CAIRO_HAS_FT_FONT=.*/CAIRO_HAS_FT_FONT=1/" ../$P-$V/build/Makefile.win32.features

vsenv

cd ../$P-$V/pixman

make -f Makefile.win32 CFG=release MMX=off pixman

cd ..

make -f Makefile.win32 \
	CFG=release \
	PIXMAN_PATH=$(cygpath -am pixman) \
	LIBPNG_PATH=$(cygpath -am $OSGEO4W_PWD/osgeo4w/lib) \
	ZLIB_PATH=$(cygpath -am $OSGEO4W_PWD/osgeo4w/lib) \
	ZLIB_CFLAGS="-I$(cygpath -am $OSGEO4W_PWD/osgeo4w/include)" \
	PNG_CFLAGS=-I$(cygpath -am $OSGEO4W_PWD/osgeo4w/include) \
	CFLAGS="-I$(cygpath -am $OSGEO4W_PWD/osgeo4w/include/freetype2)" \
	LDFLAGS="$(cygpath -am $OSGEO4W_PWD/osgeo4w/lib/freetype.lib)"

cd ../osgeo4w

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "Cairo is a 2D graphics library with support for multiple output devices (Runtime)"
ldesc: "Cairo is a 2D graphics library with support for multiple output devices (Runtime)"
category: Libs
requires: zlib libpng
maintainer: $MAINTAINER
EOF

tar -C ../$P-$V -cjf $R/$P-$V-$B.tar.bz2 \
	--xform "s,src/release/,bin/," \
    	src/release/cairo.dll

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "Cairo is a 2D graphics library with support for multiple output devices (Development)"
ldesc: "Cairo is a 2D graphics library with support for multiple output devices (Development)"
category: Libs
requires: $P
external-source: $P
maintainer: $MAINTAINER
EOF

tar -C ../$P-$V -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	--xform "s,src/release/cairo-static.lib,lib/cairo-static.lib," \
	--xform "s,src/release/cairo.lib,lib/cairo.lib," \
	--xform "s,cairo-version.h,include/cairo-version.h," \
	--xform "s,src/,include/," \
	cairo-version.h \
	src/cairo-features.h \
	src/cairo.h \
	src/cairo-deprecated.h \
	src/cairo-win32.h \
	src/cairo-script.h \
	src/cairo-ft.h \
	src/cairo-ps.h \
	src/cairo-pdf.h \
	src/cairo-svg.h \
	src/release/cairo-static.lib \
	src/release/cairo.lib

cp ../$P-$V/COPYING $R/$P-$V-$B.txt
cp ../$P-$V/COPYING $R/$P-devel/$P-devel-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
