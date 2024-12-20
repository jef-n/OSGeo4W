export P=boost
export V=1.87.0
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none
export PACKAGES="boost boost-devel"

source ../../../scripts/build-helpers

startlog

s=${P}_${V//./_}
[ -f $s.tar.bz2 ] || wget -c https://archives.boost.io/release/$V/source/$s.tar.bz2
[ -f ../$s/bootstrap.bat ] || tar -C .. -xjf $s.tar.bz2

mkdir -p build stage install

vsenv

cd ../$s

cmd /c bootstrap vc143

./b2 \
	--build-dir=../osgeo4w/build \
	--stagedir=../osgeo4w/stage \
	--build-type=minimal \
	--toolset=msvc-14.3 \
	-j 4 \
	address-model=64 \
	architecture=x86 \
	link=shared \
	threading=multi \
	variant=release

./b2 install \
	--exec-libdir=../osgeo4w/install \
	--libdir=../osgeo4w/install/lib \
	--includedir=../osgeo4w/install/include \
	--cmakedir=../osgeo4w/install/share/cmake

cmakefix ../osgeo4w/install

cd ../osgeo4w

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "Boost C++ Libraries (Runtime)"
ldesc: "Boost C++ Libraries (Runtime)"
category: Libs
requires: msvcrt2019
maintainer: $MAINTAINER
EOF

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "Boost C++ Libraries (Development)"
ldesc: "Boost C++ Libraries (Development)"
category: Libs
requires: $P
external-source: $P
maintainer: $MAINTAINER
EOF

tar -C stage -cjf $R/$P-$V-$B.tar.bz2 \
	--exclude "*.lib" \
	--exclude "lib/cmake" \
	--xform "s,^lib,bin," \
	lib

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	--exclude "*-x32-*" \
	--exclude "*.dll" \
	lib include share

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

cp ../$s/LICENSE_1_0.txt $R/$P-$V-$B.txt
cp ../$s/LICENSE_1_0.txt $R/$P-devel/$P-devel-$V-$B.txt

endlog
