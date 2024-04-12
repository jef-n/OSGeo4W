export P=xerces-c
export V=3.2.5
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none
export PACKAGES="xerces-c xerces-c-devel xerces-c-doc xerces-c-tools"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget https://downloads.apache.org/xerces/c/${V%%.*}/sources/xerces-c-$V.tar.gz
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
mkdir -p $R/$P-{devel,doc,tools}

cat <<EOF >$R/setup.hint
sdesc: "The Xerces-C 3 library for parsing XML files (runtime)"
ldesc: "The Xerces-C 3 library for parsing XML files (runtime)"
category: Libs
requires: msvcrt2019
maintainer: $MAINTAINER
EOF

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "The Xerces-C 3 library for parsing XML files (development)"
ldesc: "The Xerces-C 3 library for parsing XML files (development)"
category: Libs
requires: $P
external-source: $P
maintainer: $MAINTAINER
EOF

cat <<EOF >$R/$P-tools/setup.hint
sdesc: "The Xerces-C 3 library for parsing XML files (tools)"
ldesc: "The Xerces-C 3 library for parsing XML files (tools)"
category: Commandline_Utilities
requires: $P
external-source: $P
maintainer: $MAINTAINER
EOF

cat <<EOF >$R/$P-doc/setup.hint
sdesc: "The Xerces-C 3 library for parsing XML files (documentation)"
ldesc: "The Xerces-C 3 library for parsing XML files (documentation)"
category: Libs
requires: $P
external-source: $P
maintainer: $MAINTAINER
EOF

v=${V%.*}
v=${v/./_}

cp ../$P-$V/LICENSE $R/$P-$V-$B.txt
cp ../$P-$V/LICENSE $R/$P-devel/$P-devel-$V-$B.txt
cp ../$P-$V/LICENSE $R/$P-tools/$P-tools-$V-$B.txt
cp ../$P-$V/LICENSE $R/$P-doc/$P-doc-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	bin/xerces-c_$v.dll

tar -C install -cjf $R/$P-tools/$P-tools-$V-$B.tar.bz2 \
	--exclude bin/xerces-c_$v.dll \
	bin

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	cmake \
	lib \
	include

tar -C install -cjf $R/$P-doc/$P-doc-$V-$B.tar.bz2 \
	share

endlog
