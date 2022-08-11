export P=odbc-cpp-wrapper
export V=1.1
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget -O $P-$V.tar.gz https://github.com/SAP/$P/archive/refs/tags/v$V.tar.gz
[ -d ../$P-$V ] || tar -C .. -xzf $P-$V.tar.gz

(
	vs2019env
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
)

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "odbc cpp wrapper library"
ldesc: "odbc cpp wrapper library"
category: Libs
requires: msvcrt2019
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R//$P-$V-$B.tar.bz2 \
	--xform "s,lib/odbccpp.dll,bin/odbccpp.dll," \
	lib/odbccpp.dll

cp ../$P-$V/LICENSE $R/$P-$V-$B.txt

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "odbc cpp wrapper library (development)"
ldesc: "odbc cpp wrapper library (development)"
category: Libs
requires: $P
maintainer: $MAINTAINER
external-source: $P
EOF

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	--exclude lib/odbccpp.dll \
	include lib

cp ../$P-$V/LICENSE $R/$P-devel/$P-devel-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
