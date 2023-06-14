export P=libjxl
export V=0.8.1
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="zlib-devel libpng-devel brotli-devel"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget -O $P-$V.tar.gz https://github.com/libjxl/libjxl/archive/refs/tags/v$V.tar.gz
[ -f ../$P-$V/CMakeLists.txt ] || tar -C .. -xzf $P-$V.tar.gz
[ -d ../$P-$V/downloads ] || ( cd ../$P-$V/; GIT_DIR=download-tar-balls PATH=/bin:$PATH bash -x deps.sh )

(
	vs2019env
	cmakeenv
	ninjaenv

	export LIB="$LIB;$(cygpath -am osgeo4w/lib)"
	export INCLUDE="$INCLUDE;$(cygpath -am osgeo4w/include)"

	rm -rf build install
	mkdir build install

	cd build

	cmake -G Ninja \
		-D CMAKE_BUILD_TYPE=Release \
		-D CMAKE_INSTALL_PREFIX=$(cygpath -am ../install) \
		-D BUILD_TESTING=OFF \
		-D JPEGXL_FORCE_SYSTEM_BROTLI=ON \
		../../$P-$V

	cmake --build .
	cmake --install . || cmake --install .
)

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-{devel,tools}

cat <<EOF >$R/setup.hint
sdesc: "JPEG XL reference implementation (runtime)"
ldesc: "JPEG XL reference implementation (runtime)"
category: Libs
requires: msvcrt2019 zlib
maintainer: $MAINTAINER
EOF

cat <<EOF >$R/$P-tools/setup.hint
sdesc: "JPEG XL reference implementation (tools)"
ldesc: "JPEG XL reference implementation (tools)"
category: Libs
requires: $P
external-source: $P
maintainer: $MAINTAINER
EOF

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "JPEG XL reference implementation (development)"
ldesc: "JPEG XL reference implementation (development)"
category: Libs
requires: $P
external-source: $P
maintainer: $MAINTAINER
EOF

cp ../$P-$V/LICENSE $R/$P-$V-$B.txt
cp ../$P-$V/LICENSE $R/$P-devel/$P-devel-$V-$B.txt
cp ../$P-$V/LICENSE $R/$P-tools/$P-tools-$V-$B.txt

tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	--exclude "*.exe" \
	bin/

tar -C install -cjf $R/$P-tools/$P-tools-$V-$B.tar.bz2 \
	--exclude "*.dll" \
	bin

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	include \
	lib

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 \
	osgeo4w/package.sh

endlog
