export P=laszip
export V=3.4.3
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none
export PACKAGES="laszip laszip-devel"

source ../../../scripts/build-helpers

startlog

[ -f $P-src-$V.tar.gz ] || wget https://github.com/LASzip/LASzip/releases/download/$V/$P-src-$V.tar.gz
[ -f ../$P-src-$V/CMakeLists.txt ] || tar -C .. -xzf $P-src-$V.tar.gz

(
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
		../../$P-src-$V
	ninja
	ninja install
	cmakefix ../install
)

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "LASzip - free and lossless LiDAR compression (Runtime)"
ldesc: "LASzip - free and lossless LiDAR compression"
category: Libs
requires: msvcrt2019
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	bin

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "LASzip - free and lossless LiDAR compression (Development)"
ldesc: "LASzip - free and lossless LiDAR compression"
category: Libs
requires: $P
maintainer: $MAINTAINER
external-source: $P
EOF

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	include lib

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
