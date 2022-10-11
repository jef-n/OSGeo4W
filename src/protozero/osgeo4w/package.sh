export P=protozero
export V=1.7.1
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget -c -O $P-$V.tar.gz https://github.com/mapbox/$P/archive/refs/tags/v$V.tar.gz
[ -f ../$P-$V/CMakeLists.txt ] || tar -C .. -xzf $P-$V.tar.gz

vs2019env
cmakeenv

# for some reason doesn't build using ninja - use jom
[ -x jom.exe ] || {
	wget https://download.qt.io/official_releases/jom/jom_1_1_2.zip
	unzip jom_1_1_2.zip jom.exe
	chmod a+rx jom.exe
}

export PATH=$PWD:$PATH

mkdir -p build install
cd build

cmake -G "NMake Makefiles JOM" \
	-D CMAKE_BUILD_TYPE=Release \
	-D CMAKE_INSTALL_PREFIX=../install \
	-D BUILD_TESTING=OFF \
	../../$P-$V
cmake --build .
cmake --build . --target install

cd ../install

export R=$OSGEO4W_REP/x86_64/release/$P-devel
mkdir -p $R

cat <<EOF >$R/setup.hint
sdesc: "Minimalistic protocol buffer decoder and encoder in C++"
ldesc: "Minimalistic protocol buffer decoder and encoder in C++."
category: Libs
requires: msvcrt2019
maintainer: $MAINTAINER
EOF
cp ../../$P-$V/LICENSE.md $R/$P-devel-$V-$B.txt

tar -cjf $R/$P-devel-$V-$B.tar.bz2 include

cd ..

tar -C .. -cjf $R/$P-devel-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
