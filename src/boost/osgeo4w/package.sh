export P=boost
export V=1.74.0
export B=next
export MAINTAINER=JuergenFischer

source ../../../scripts/build-helpers

startlog

[ -f ${P}_${V//./_}.tar.gz ] || wget -c https://dl.bintray.com/boostorg/release/$V/source/${P}_${V//./_}.tar.gz
[ -f ../bootstrap.bat ] || tar -C .. -xzf ${P}_${V//./_}.tar.gz --xform "s,^${P}_${V//./_},.,"

VCARCH=x86 vs2019env	# oddness: boost wants the 32bit tools even for 64-bit

mkdir -p build stage install

cd ..

cmd /c bootstrap vc142

./b2 \
	--build-dir=osgeo4w/build \
	--stagedir=osgeo4w/stage \
	--build-type=minimal \
	--toolset=msvc-14.2 \
	-j 4 \
	address-model=64 \
	architecture=x86 \
	link=shared \
	threading=multi \
	variant=release

./b2 install \
	--exec-libdir=osgeo4w/install \
	--libdir=osgeo4w/install/lib \
	--includedir=osgeo4w/install/include \
	--cmakedir=osgeo4w/install/share/cmake

cd osgeo4w

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

cp ../LICENSE_1_0.txt $R/$P-$V-$B.txt
cp ../LICENSE_1_0.txt $R/$P-devel/$P-devel-$V-$B.txt

endlog
