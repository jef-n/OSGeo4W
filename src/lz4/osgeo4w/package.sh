export P=lz4
export V=1.9.4
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none
export PACKAGES="lz4 lz4-devel"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget -O $P-$V.tar.gz https://github.com/$P/$P/archive/refs/tags/v$V.tar.gz
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
		-D BUILD_STATIC_LIBS=ON \
		-D BUILD_SHARED_LIBS=ON \
		../../$P-$V/build/cmake
	cmake --build .
	cmake --install .
	cmakefix ../install
)

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-{devel,tools}

cat <<EOF >$R/setup.hint
sdesc: "LZ4 compression (runtime)"
ldesc: "LZ4 compression (runtime)"
category: Libs
requires: msvcrt2019
maintainer: $MAINTAINER
EOF

cp ../$P-$V/LICENSE $R/$P-$V-$B.txt
tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	--exclude "*.exe" \
	bin

cat <<EOF >$R/$P-tools/setup.hint
sdesc: "LZ4 compression (tools)"
ldesc: "LZ4 compression (tools)"
category: Libs
requires: msvcrt2019 $P
maintainer: $MAINTAINER
EOF

cp ../$P-$V/LICENSE $R/$P-tools/$P-tools-$V-$B.txt
tar -C install -cjf $R/$P-tools/$P-tools-$V-$B.tar.bz2 \
	--exclude "*.dll" \
	bin

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "LZ4 compression (development)"
ldesc: "LZ4 compression (development)"
category: Libs
requires: $P
maintainer: $MAINTAINER
external-source: $P
EOF

cp ../$P-$V/LICENSE $R/$P-devel/$P-devel-$V-$B.txt
tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 include lib share

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
