export P=nlohmann-json-devel
export V=3.12.0
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none
export PACKAGES="nlohmann-json-devel"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.xz ] || wget -O $P-$V.tar.xz https://github.com/nlohmann/json/releases/download/v$V/json.tar.xz
[ -f ../$P-$V/CMakeLists.txt ] || tar --xform s,^json,$P-$V, -C .. -xJf $P-$V.tar.xz

(
	vsenv
	cmakeenv
	ninjaenv

	mkdir -p build install
	cd build

	export LIB="$(cygpath -am ../osgeo4w/lib);$LIB"
	export INCLUDE="$(cygpath -am ../include);$(cygpath -am ../osgeo4w/include);$INCLUDE"

	cmake -G Ninja \
		-D CMAKE_BUILD_TYPE=Release \
		-D CMAKE_INSTALL_PREFIX=../install \
		-D JSON_BuildTests=OFF \
		../../$P-$V
	cmake --build .
	cmake --build . --target install
	cmakefix ../install
)

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R

cat <<EOF >$R/setup.hint
sdesc: "JSON for modern C++ (development)"
ldesc: "JSON for modern C++ (development)"
category: Libraries
requires: msvcrt2019
maintainer: $MAINTAINER
requires:
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 .

cp ../$P-$V/LICENSE.MIT $R/$P-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
