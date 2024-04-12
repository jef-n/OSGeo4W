export P=wingetopt-devel
export V=1.00
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none
export PACKAGES="wingetopt-devel"

source ../../../scripts/build-helpers

startlog

export p=${P%-devel}
[ -f $p-$V.tar.gz ] || wget -O $p-$V.tar.gz https://github.com/alex85k/$p/archive/refs/tags/v$V.tar.gz
[ -f ../$p-$V/CMakeLists.txt ] || tar -C .. -xzf $p-$V.tar.gz

(
	vsenv
	cmakeenv
	ninjaenv

	mkdir -p build install
	cd build

	export LIB="$(cygpath -am osgeo4w/lib);$LIB"
	export INCLUDE="$(cygpath -am osgeo4w/include);$INCLUDE"

	cmake -G Ninja \
		-D CMAKE_BUILD_TYPE=Release \
		-D CMAKE_INSTALL_PREFIX=../install \
		../../$p-$V
	cmake --build .
	cmake --build . --target install
	cmakefix ../install
)

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R

cat <<EOF >$R/setup.hint
sdesc: "getopt library for Windows compilers (Development)"
ldesc: "getopt library for Windows compilers (Development)"
category: Libs
maintainer: $MAINTAINER
requires:
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 include lib

cp ../$p-$V/LICENSE $R/$P-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
