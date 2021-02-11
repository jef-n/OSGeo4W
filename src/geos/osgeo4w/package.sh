export P=geos
export V=3.9.1
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none

source ../../../scripts/build-helpers

startlog

[ -f geos-$V.tar.bz2 ] || wget https://download.osgeo.org/geos/geos-$V.tar.bz2
[ -f ../CMakeLists.txt ] || tar -C .. -xjf geos-$V.tar.bz2 --xform s,geos-$V,.,

vs2019env
cmakeenv

mkdir -p install build

cd build

cmake -G Ninja \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_INSTALL_PREFIX=../install \
        ../..
ninja
ninja install

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

cp ../COPYING $R/$P-$V-$B.txt
cp ../COPYING $R/$P-devel/$P-devel-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

cd install

tar -cjf $R/$P-$V-$B.tar.bz2 \
	bin/*.dll

tar -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	lib \
	include

endlog
