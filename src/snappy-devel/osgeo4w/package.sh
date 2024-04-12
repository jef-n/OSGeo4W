export P=snappy-devel
export V=1.1.10
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none
export PACKAGES=snappy-devel

source ../../../scripts/build-helpers

startlog

export p=${P%-devel}
[ -f $p-$V.tar.gz ] || wget -O $p-$V.tar.gz https://github.com/google/$p/archive/refs/tags/$V.tar.gz
[ -d ../$p-$V ] || tar -C .. -xzf $p-$V.tar.gz

(
	vsenv
	cmakeenv
	ninjaenv

	mkdir -p build install
	cd build

	cmake -G Ninja \
		-D CMAKE_BUILD_TYPE=Release \
		-D CMAKE_INSTALL_PREFIX=../install \
		-D PROJECT_BINARY_DIR=share \
		-D SNAPPY_BUILD_TESTS=OFF \
		-D SNAPPY_BUILD_BENCHMARKS=OFF \
		-D SNAPPY_HAVE_BMI2=OFF \
		../../$p-$V
	cmake --build .
	cmake --install .
	cmakefix ../install
)

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R

cat <<EOF >$R/setup.hint
sdesc: "snappy compression (development)"
ldesc: "snappy compression (development)"
category: Libs
requires: 
maintainer: $MAINTAINER
EOF

cp ../$p-$V/COPYING $R/$P-$V-$B.txt
tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	--xform "s,lib/cmake,share/cmake," \
	include \
	lib

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
