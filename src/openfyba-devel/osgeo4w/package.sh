export P=openfyba-devel
export V=tbd
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none
export PACKAGES="openfyba-devel"

source ../../../scripts/build-helpers

startlog

export V=$(date +%Y%m%d)

p=${P%-devel}
[ -f master.tar.gz ] || wget https://github.com/kartverket/fyba/archive/master.tar.gz
[ -f ../$p-$V/CMakeLists.txt ] || tar -C .. -xzf master.tar.gz --xform "s,^fyba-master,$p-$V,"
[ -f patched ] || {
	patch -d ../$p-$V -p1 --dry-run <diff
	patch -d ../$p-$V -p1 <diff
	touch patched
}

vsenv
cmakeenv
ninjaenv

mkdir -p build install

cd build

cmake -G Ninja \
	-D CMAKE_BUILD_TYPE=Release \
	-D CMAKE_INSTALL_PREFIX=../install \
	../../$p-$V
ninja
ninja install
cmakefix ../install

cd ..

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R

cat <<EOF >$R/setup.hint
sdesc: "OpenFYBA library"
ldesc: "OpenFYBA is the source code release of the FYBA library, distributed by the National Mapping Authority of Norway (Kartverket) to read and write files in the National geodata standard format SOSI (https://github.com/kartverket/fyba)."
category: Libs
maintainer: $MAINTAINER
requires: msvcrt2019
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 include lib
tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh osgeo4w/diff

endlog
