export P=libjpeg-turbo
export V=2.0.7-esr
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=zlib-devel

NASM=2.15.05

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget -O $P-$V.tar.gz https://github.com/$P/$P/archive/refs/tags/$V.tar.gz
[ -f ../$P-$V/CMakeLists.txt ] || tar -C .. -xzf $P-$V.tar.gz

if ! [ -d nasm-$NASM ]; then
        wget -c https://www.nasm.us/pub/nasm/releasebuilds/$NASM/win64/nasm-$NASM-win64.zip
        unzip nasm-$NASM-win64.zip
fi

(
	vs2019env
	cmakeenv
	ninjaenv

	export PATH=$PATH:$(cygpath -a nasm-$NASM)

	rm -rf build install
	mkdir build install

	cd build

	cmake -G Ninja \
		-D CMAKE_BUILD_TYPE=Release \
		-D CMAKE_INSTALL_PREFIX=$(cygpath -am ../install) \
		-D CMAKE_INSTALL_DOCDIR=$(cygpath -am ../install/apps/$P/doc) \
		../../$P-$V

	cmake --build .
	cmake --install . || cmake --install .
)

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-{devel,tools}

cat <<EOF >$R/setup.hint
sdesc: "A JPEG image codec that uses SIMD instructions to accelerate baseline JPEG compression and decompression (runtime)"
ldesc: "A JPEG image codec that uses SIMD instructions to accelerate baseline JPEG compression and decompression (runtime)"
category: Libs
requires: msvcrt2019 zlib
maintainer: $MAINTAINER
EOF

cat <<EOF >$R/$P-tools/setup.hint
sdesc: "A JPEG image codec that uses SIMD instructions to accelerate baseline JPEG compression and decompression (tools)"
ldesc: "A JPEG image codec that uses SIMD instructions to accelerate baseline JPEG compression and decompression (tools)"
category: Libs
requires: $P
external-source: $P
maintainer: $MAINTAINER
EOF

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "A JPEG image codec that uses SIMD instructions to accelerate baseline JPEG compression and decompression (development)"
ldesc: "A JPEG image codec that uses SIMD instructions to accelerate baseline JPEG compression and decompression (development)"
category: Libs
requires: $P
external-source: $P
maintainer: $MAINTAINER
EOF

cp ../libjpeg-turbo-2.0.7-esr/LICENSE.md $R/$P-$V-$B.txt
cp ../libjpeg-turbo-2.0.7-esr/LICENSE.md $R/$P-devel/$P-devel-$V-$B.txt

tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	--exclude "*.exe" \
	bin/

tar -C install -cjf $R/$P-tools/$P-tools-$V-$B.tar.bz2 \
	--exclude "*.dll" \
	bin \
	apps/$P/

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	include \
	lib

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 \
	osgeo4w/package.sh

endlog
