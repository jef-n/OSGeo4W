export P=geos
export V=3.14.1
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none
export PACKAGES="geos geos-devel"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.bz2 ] || wget https://download.osgeo.org/$P/$P-$V.tar.bz2
[ -d ../$P-$V ] || {
	tar -C .. -xjf $P-$V.tar.bz2
	rm -fr build
}

vsenv
cmakeenv
ninjaenv

mkdir -p install build

cd build

CXXFLAGS="/D_DISABLE_CONSTEXPR_MUTEX_CONSTRUCTOR" \
cmake -G Ninja \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_INSTALL_PREFIX=../install \
        ../../$P-$V
cmake --build .
cmake --build . --target install || cmake --build . --target install
cmakefix ../install

cd ..

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "The GEOS geometry library (Runtime)"
ldesc: "The GEOS geometry library (Runtime)"
category: Libs
requires: msvcrt2019
Maintainer: $MAINTAINER
EOF

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "The GEOS geometry library (Development)"
ldesc: "The GEOS geometry library (Development)"
category: Libs
requires: $P
external-source: $P
Maintainer: $MAINTAINER
EOF

cp ../$P-$V/COPYING $R/$P-$V-$B.txt
cp ../$P-$V/COPYING $R/$P-devel/$P-devel-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

cd install

tar -cjf $R/$P-$V-$B.tar.bz2 \
	bin/

tar -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	lib \
	include

endlog
