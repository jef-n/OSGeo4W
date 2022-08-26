export P=wingetopt
export V=1.00
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none

source ../../../scripts/build-helpers

startlog
[ -f $P-$V.tar.gz ] || wget -O $P-$V.tar.gz https://github.com/alex85k/$P/archive/refs/tags/v$V.tar.gz
[ -f ../$P-$V/CMakeLists.txt ] || tar -C .. -xzf $P-$V.tar.gz

(
	vs2019env
	cmakeenv
	ninjaenv

	mkdir -p build install
	cd build

	export LIB="$(cygpath -am osgeo4w/lib);$LIB"
	export INCLUDE="$(cygpath -am osgeo4w/include);$INCLUDE"

	cmake -G Ninja \
		-D CMAKE_BUILD_TYPE=Release \
		-D CMAKE_INSTALL_PREFIX=../install \
		../../$P-$V
	cmake --build .
	cmake --build . --target install
)

export R=$OSGEO4W_REP/x86_64/release/$P-devel
mkdir -p $R

cat <<EOF >$R/setup.hint
sdesc: "getopt library for Windows compilers (Development)"
ldesc: "getopt library for Windows compilers (Development)"
category: Libs
maintainer: $MAINTAINER
requires:
EOF

tar -C install -cjf $R/$P-devel-$V-$B.tar.bz2 include lib

cp ../$P-$V/LICENSE $R/$P-devel-$V-$B.txt

tar -C .. -cjf $R/$P-devel-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
