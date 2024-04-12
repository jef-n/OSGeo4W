export P=libharu
export V=2.4.4
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="libpng-devel zlib-devel"
export PACKAGES="libharu libharu-devel"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget -O $P-$V.tar.gz https://github.com/$P/$P/archive/refs/tags/v$V.tar.gz
[ -f ../$P-$V/CMakeLists.txt ] || tar -C .. -xzf $P-$V.tar.gz

vsenv
cmakeenv
ninjaenv

mkdir -p build install
cd build

cmake -G Ninja \
	-D CMAKE_BUILD_TYPE=Release \
	-D CMAKE_INSTALL_PREFIX=../install \
        -D ZLIB_LIBRARY=$(cygpath -am ../osgeo4w/lib/zlib.lib) \
        -D ZLIB_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
        -D PNG_LIBRARY=$(cygpath -am ../osgeo4w/lib/libpng16.lib) \
        -D PNG_PNG_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	../../$P-$V
ninja
ninja install
cmakefix ../install

cd ..

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "Free, cross platform, open-sourced software library for generating PDF (runtime)"
ldesc: "Haru is a free, cross platform, open-sourced software library for generating PDF."
category: Libs
requires: msvcrt2019 zlib libpng
maintainer: $MAINTAINER
EOF

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "Free, cross platform, open-sourced software library for generating PDF (runtime)"
ldesc: "Haru is a free, cross platform, open-sourced software library for generating PDF."
category: Libs
requires: $P
external-source: $P
maintainer: $MAINTAINER
EOF

tee $R/$P-devel/$P-devel-$V-$B.txt <<EOF >$R/$P-$V-$B.txt
Haru is distributed under the ZLIB/LIBPNG License. Because ZLIB/LIBPNG License
is one of the freest licenses, You can use Haru for various purposes.

The license of Haru is as follows.

Copyright (C) 1999-2006 Takeshi Kanno
Copyright (C) 2007-2009 Antony Dovgal

This software is provided 'as-is', without any express or implied warranty.

In no event will the authors be held liable for any damages arising from the
use of this software.

Permission is granted to anyone to use this software for any purpose,including
commercial applications, and to alter it and redistribute it freely, subject
to the following restrictions:

 1. The origin of this software must not be misrepresented; you must not claim
    that you wrote the original software. If you use this software in a
    product, an acknowledgment in the product documentation would be
    appreciated but is not required.
 2. Altered source versions must be plainly marked as such, and must not be
    misrepresented as being the original software.
 3. This notice may not be removed or altered from any source distribution.

EOF

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

tar -C install -cjf $R/$P-$V-$B.tar.bz2 bin/hpdf.dll

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	--exclude "lib/libpng16.lib" \
	--exclude "lib/zlib.lib" \
	include \
	lib

endlog
