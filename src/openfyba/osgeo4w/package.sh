export P=openfyba
export V=20150103
export B="next openfyba-devel"
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none

source ../../../scripts/build-helpers

startlog

[ -f master.tar.gz ] || wget -q https://github.com/kartverket/fyba/archive/master.tar.gz
[ -f ../CMakeLists.txt ] || tar -C .. -xzf master.tar.gz --xform "s,^fyba-master,.,"
[ -f patched ] || {
	patch -d .. -p1 --dry-run <diff
	patch -d .. -p1 <diff
	touch patched
}

vs2019env
cmakeenv
ninjaenv

mkdir -p build install

cd build

cmake -G Ninja \
	-D CMAKE_BUILD_TYPE=Release \
	-D CMAKE_INSTALL_PREFIX=../install \
	../..
ninja
ninja install

cd ..

P=$P-devel

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
