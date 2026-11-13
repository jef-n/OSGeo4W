export P=lcms2
export V=2.20
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="libtiff-devel libjpeg-turbo-devel"
export PACKAGES="lcms2 lcms2-devel"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget -O $P-$V.tar.gz https://github.com/mm2/Little-CMS/archive/refs/tags/lcms$V.tar.gz
[ -f ../$P-$V/CMakeLists.txt ] || tar -C .. --xform "s,^Little-CMS-lcms$V,$P-$V," -xzf $P-$V.tar.gz
[ -f ../$P-$V/patched ] || {
	patch -p1 -d ../$P-$V --dry-run <patch
	patch -p1 -d ../$P-$V <patch >../$P-$V/patched
}

vsenv
cmakeenv
ninjaenv

mkdir -p build install

cd build
cmake -G Ninja \
	-Wno-dev \
	-D CMAKE_BUILD_TYPE=Release \
	-D CMAKE_INSTALL_PREFIX=../install \
	-D JPEG_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
        -D JPEG_LIBRARY=$(cygpath -am ../osgeo4w/lib/jpeg.lib) \
	-D TIFF_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D TIFF_LIBRARIES=$(cygpath -am ../osgeo4w/lib/tiff.lib) \
	../../$P-$V
ninja
ninja install
cmakefix ../install

cd ..

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-{tools,devel}

cat <<EOF >$R/setup.hint
sdesc: "Little CMS (runtime)"
ldesc: "Little CMS"
category: Libs
requires: msvcrt2019 libtiff libjpeg-turbo
maintainer: $MAINTAINER
EOF

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "Little CMS (development)"
ldesc: "Little CMS"
category: Libs
requires: $P
external-source: $P
maintainer: $MAINTAINER
EOF

cat <<EOF >$R/$P-tools/setup.hint
sdesc: "Little CMS (tools)"
ldesc: "Little CMS"
category: Libs
requires: $P
external-source: $P
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	bin/$P.dll

tar -C install -cjf $R/$P-tools/$P-tools-$V-$B.tar.bz2 \
	--exclude "bin/*.dll" \
	bin share

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	include lib

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 \
	osgeo4w/package.sh osgeo4w/patch

cp ../$P-$V/LICENSE $R/$P-$V-$B.txt
cp ../$P-$V/LICENSE $R/$P-devel/$P-devel-$V-$B.txt
cp ../$P-$V/LICENSE $R/$P-tools/$P-tools-$V-$B.txt

endlog
