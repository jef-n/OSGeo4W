export P=utf8proc
export V=2.7.0
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget -O $P-$V.tar.gz "https://github.com/JuliaStrings/$P/archive/refs/tags/v$V.tar.gz"
[ -d ../$P-$V ] || tar -C .. -xzf $P-$V.tar.gz

(
	vs2019env
	cmakeenv
	ninjaenv

	mkdir -p build install
	cd build

	export LIB="$(cygpath -am osgeo4w/lib);$LIB"
	export INCLUDE="$(cygpath -am osgeo4w/include);$INCLUDE"

	cmake -G Ninja \
		-D CMAKE_BUILD_TYPE=Release \
		-D CMAKE_INSTALL_PREFIX=../install \
		../../$P-$V/

	cmake --build .
	cmake --build . --target install
)

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R

cat <<EOF >$R/setup.hint
sdesc: unicode library
ldesc: "small, clean C library that provides Unicode
normalization, case-folding, and other
operations for data in the UTF-8 encoding)."
category: Libs
requires: msvcrt2019
maintainer: $MAINTAINER
EOF

cp ../$P-$V/LICENSE.md $R/$P-$V-$B.txt
tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	include/utf8proc.h \
	lib/pkgconfig/libutf8proc.pc \
	lib/utf8proc_static.lib

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
