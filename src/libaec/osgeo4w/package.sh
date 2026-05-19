export P=libaec
export V=1.1.6
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none
export PACKAGES="libaec libaec-devel"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget -O $P-$V.tar.gz https://github.com/Deutsches-Klimarechenzentrum/libaec/releases/download/v$V/$P-$V.tar.gz
[ -f ../$P-$V/CMakeLists.txt ] || tar -C .. -xzf $P-$V.tar.gz

vsenv
cmakeenv
ninjaenv

mkdir -p build install
cd build

cmake -G Ninja \
	-D CMAKE_BUILD_TYPE=Release \
	-D CMAKE_INSTALL_PREFIX=../install \
	../../$P-$V
ninja
ninja install
cmakefix ../install

cd ..

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "Adaptive Entropy Coding library (runtime library)"
ldesc: "Adaptive Entropy Coding library (runtime library)"
category: Libs
requires: msvcrt2019
maintainer: $MAINTAINER
EOF

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "Adaptive Entropy Coding library (development)"
ldesc: "Adaptive Entropy Coding library (development)"
maintainer: $MAINTAINER
category: Libs
requires: $P
external-source: $P
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	bin/aec.dll \
	bin/szip.dll

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	include \
	lib

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

cp ../$P-$V/LICENSE.txt $R/$P-$V-$B.txt
cp ../$P-$V/LICENSE.txt $R/$P-devel/$P-devel-$P-$V-$B.txt

mkdir -p $OSGEO4W_REP/x86_64/release/szip/szip-devel

cat <<EOF >$OSGEO4W_REP/x86_64/release/szip/setup.hint
sdesc: "SZIP compression library (transitional package)"
ldesc: "SZIP compression library (transitional package)"
category: _obsolete
requires: $P
maintainer: $MAINTAINER
external-source: $P $V-$B
EOF

cat <<EOF >$OSGEO4W_REP/x86_64/release/szip/szip-devel/setup.hint
sdesc: "SZIP compression library (transitional package)"
ldesc: "SZIP compression library (transitional package)"
category: _obsolete
requires: $P-devel
maintainer: $MAINTAINER
external-source: $P $V-$B
EOF

d=$(mktemp -d)
tar -C $d -cjf $OSGEO4W_REP/x86_64/release/szip/szip-99-1.tar.bz2 .
tar -C $d -cjf $OSGEO4W_REP/x86_64/release/szip/szip-devel/szip-devel-99-1.tar.bz2 .
rmdir $d

endlog
