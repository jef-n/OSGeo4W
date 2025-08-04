export P=protozero-devel
export V=1.8.1
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none
export PACKAGES="protozero-devel"

source ../../../scripts/build-helpers

startlog

export p=${P%-devel}
[ -f $p-$V.tar.gz ] || wget -c -O $p-$V.tar.gz https://github.com/mapbox/$p/archive/refs/tags/v$V.tar.gz
[ -f ../$p-$V/CMakeLists.txt ] || tar -C .. -xzf $p-$V.tar.gz
[ -f ../$p-$V/patched ] || {
	patch -p1 -d ../$p-$V --dry-run <patch
	patch -p1 -d ../$p-$V <patch
	touch ../$p-$V/patched
}

vsenv
cmakeenv
ninjaenv

mkdir -p build install
cd build

type -p cmake
type -p ninja
type -p cl

cmake -G Ninja \
	-D CMAKE_BUILD_TYPE=Release \
	-D CMAKE_INSTALL_PREFIX=$(cygpath -aw ../install) \
	-D BUILD_TESTING=OFF \
	../../$p-$V
cmake --build .
cmake --build . --target install
cmakefix ../install

cd ../install

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R

cat <<EOF >$R/setup.hint
sdesc: "Minimalistic protocol buffer decoder and encoder in C++"
ldesc: "Minimalistic protocol buffer decoder and encoder in C++."
category: Libs
requires: msvcrt2019
maintainer: $MAINTAINER
EOF
cp ../../$p-$V/LICENSE.md $R/$P-$V-$B.txt

tar -cjf $R/$P-$V-$B.tar.bz2 include

cd ..

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
