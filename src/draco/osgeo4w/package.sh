export P=draco
export V=1.5.7
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-core"
export PACKAGES="draco draco-devel"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget -O $P-$V.tar.gz https://github.com/google/$P/archive/refs/tags/$V.tar.gz
[ -f ../$P-$V/CMakeLists.txt ] || tar -C .. -xzf $P-$V.tar.gz
if ! [ -f ../$P-$V/patched ]; then
	patch -p1 -d ../$P-$V --dry-run <patch
	patch -p1 -d ../$P-$V <patch
	touch  ../$P-$V/patched
fi

(
	set -e

	vsenv
	cmakeenv
	ninjaenv

	mkdir -p build install
	cd build

	export LIB="$(cygpath -aw ../osgeo4w/lib);$LIB"
	export INCLUDE="$(cygpath -aw ../osgeo4w/include);$INCLUDE"

	cmake -G Ninja \
		-D CMAKE_BUILD_TYPE=Release \
		-D CMAKE_INSTALL_PREFIX=../install \
		-D PYTHON_EXECUTABLE=$(cygpath -am ../osgeo4w/bin/python3.exe) \
		../../$P-$V
	cmake --build .
	cmake --build . --target install || cmake --build . --target install
	cmakefix ../install
)

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "draco: 3D data compression (executables)"
ldesc: "Draco is a library for compressing and decompressing 3D geometric meshes and point clouds. It is intended to improve the storage and transmission of 3D graphics."
category: Commandline_Utilities
requires:
category: Libs
requires: msvcrt2019
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 bin
cp ../$P-$V/LICENSE $R/$P-$V-$B.txt

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "draco: 3D data compression (development)"
ldesc: "Draco is a library for compressing and decompressing 3D geometric meshes and point clouds. It is intended to improve the storage and transmission of 3D graphics."
category: Libs
requires:
maintainer: $MAINTAINER
external-source: $P
EOF

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 include lib share
cp ../$P-$V/LICENSE $R/$P-devel/$P-devel-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh osgeo4w/patch

endlog
