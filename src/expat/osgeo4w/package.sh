export P=expat
export V=2.2.10
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.bz2 ] || wget https://github.com/libexpat/libexpat/releases/download/R_${V//./_}/expat-$V.tar.bz2
[ -f ../CMakeLists.txt ] || tar -C .. -xjf  $P-$V.tar.bz2 --xform "s,^$P-$V,.,"

vs2019env
cmakeenv
ninjaenv

mkdir -p build
cd build

cmake -G Ninja \
	-D CMAKE_BUILD_TYPE=Release \
	-D CMAKE_INSTALL_PREFIX=../install \
	../..
ninja
ninja install

cd ..

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "The Expat XML Parser library (Runtime)"
ldesc: "The Expat XML Parser library (Runtime)"
category: Libs
requires: msvcrt2019
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	bin/libexpat.dll

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "The Expat XML Parser library (Development)"
ldesc: "The Expat XML Parser library (Development)"
category: Libs
requires: $P
maintainer: $MAINTAINER
external-source: $P
EOF

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	bin/xmlwf.exe \
	include \
	lib \
	share

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
