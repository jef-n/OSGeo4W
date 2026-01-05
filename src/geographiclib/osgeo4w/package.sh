export P=geographiclib
export V=2.7
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none
export PACKAGES="geographiclib geographiclib-tools geographiclib-devel"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget -O $P-$V.tar.gz "https://sourceforge.net/projects/$P/files/distrib-C%2B%2B/GeographicLib-$V.tar.gz/download"
[ -f ../$P-$V/CMakeLists.txt ] || tar -C .. -xzf $P-$V.tar.gz

vsenv
cmakeenv
ninjaenv

rm -rf install
mkdir -p build-$V install
cd build-$V

export INCLUDE="$INCLUDE;$(cygpath -aw osgeo4w/include)"
export LIB="$LIB;$(cygpath -aw osgeo4w/lib)"
export PATH="$PATH:$OSGEO4W_PWD/osgeo4w/bin"

cmake -G Ninja \
	-D CMAKE_BUILD_TYPE=Release \
	-D CMAKE_INSTALL_PREFIX=../install \
	../../$P-$V
cmake --build .
cmake --build . --target install || cmake --build . --target install
cmakefix ../install

cd ..

export R=$OSGEO4W_REP/x86_64/release/$P

mkdir -p $R/$P-{devel,tools}

cat <<EOF >$R/setup.hint
sdesc: "C++ library to solve some geodesic problems (runtime)."
ldesc: "C++ library to solve some geodesic problems (runtime)."
category: Libs
requires: msvcrt2019
maintainer: $MAINTAINER
EOF

cat <<EOF >$R/$P-tools/setup.hint
sdesc: "C++ library to solve some geodesic problems (tools)."
ldesc: "C++ library to solve some geodesic problems (tools)."
category: Commandline_Utilities
requires: $P
maintainer: $MAINTAINER
external-source: $P
EOF

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "C++ library to solve some geodesic problems (development)."
ldesc: "C++ library to solve some geodesic problems (development)."
category: Libs
requires: $P $P-tools
maintainer: $MAINTAINER
external-source: $P
EOF

appendversions $R/setup.hint
appendversions $R/$P-tools/setup.hint
appendversions $R/$P-devel/setup.hint

cp ../$P-$V/LICENSE.txt $R/$P-$V-$B.txt
cp ../$P-$V/LICENSE.txt $R/$P-tools/$P-tools-$V-$B.txt
cp ../$P-$V/LICENSE.txt $R/$P-devel/$P-devel-$V-$B.txt

tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	bin/GeographicLib.dll

tar -C install -cjf $R/$P-tools/$P-tools-$V-$B.tar.bz2 \
	--exclude "*.dll" \
	bin

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	include \
	share \
	lib

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
