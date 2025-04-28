export P=muparser
export V=2.3.5
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none
export PACKAGES="muparser muparser-devel"

source ../../../scripts/build-helpers

startlog

[ -f muparser-$V.tar.gz ] || wget -O $P-$V.tar.gz https://github.com/beltoforion/$P/archive/refs/tags/v$V.tar.gz
[ -d ../$P-$V ] || tar -C .. -xzf $P-$V.tar.gz

(
	vsenv
	cmakeenv
	ninjaenv

	mkdir -p build install
	cd build

	cmake -G Ninja \
		-D CMAKE_BUILD_TYPE=Release \
		-D CMAKE_INSTALL_PREFIX=../install \
		../../$P-$V

	cmake --build .
	cmake --build . --target install

	cmakefix ../install
)

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "fast math parser library (runtime)"
ldesc: "fast math parser library (runtime)"
category: Libs
requires: msvcrt2019 
maintainer: $MAINTAINER
EOF

cp ../$P-$V/LICENSE $R/$P-$V-$B.txt
tar -C install -cjf $R/$P-$V-$B.tar.bz2 bin

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "fast math parser library (development)"
ldesc: "fast math parser library (development)"
category: Libs
requires: $P
maintainer: $MAINTAINER
external-source: $P
EOF

cp ../$P-$V/LICENSE $R/$P-devel/$P-devel-$V-$B.txt
tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 include lib

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
