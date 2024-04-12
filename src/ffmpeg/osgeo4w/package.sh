export P=ffmpeg
export V=6.1.1
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none
export PACKAGES="ffmpeg ffmpeg-devel"

NASM=2.15.05

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.bz2 ] || wget -q http://ffmpeg.org/releases/$P-$V.tar.bz2
[ -f ../$P-$V/configure ] || tar -C .. -xjf $P-$V.tar.bz2

if ! [ -d nasm-$NASM ]; then
        wget -c https://www.nasm.us/pub/nasm/releasebuilds/$NASM/win64/nasm-$NASM-win64.zip
        unzip nasm-$NASM-win64.zip
fi

(
	set -e
	export PATH=$PATH:$(cygpath -a nasm-$NASM)

	vsenv

	export LIB="$(cygpath -aw ../osgeo4w/lib);$LIB"
	export INCLUDE="$(cygpath -aw ../osgeo4w/include);$INCLUDE"

	mkdir -p install/{bin,apps/ffmpeg/{data,man,doc},share/pkgconfig}

	cd ../$P-$V

	INSTDIR=../osgeo4w/install

	[ -f config.h ] || ./configure --toolchain=msvc \
		--prefix=$INSTDIR \
		--bindir=/bin \
		--shlibdir=/bin \
		--libdir=/lib \
		--incdir=/include \
		--datadir=/apps/$P/data \
		--mandir=/apps/$P/man \
		--docdir=/apps/$P/doc \
  		--pkgconfigdir=/share/pkgconfig
	make -j

	make DESTDIR=../osgeo4w/install install
)

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "A complete, cross-platform solution to record, convert and stream audio and video."
ldesc: "A complete, cross-platform solution to record, convert and stream audio and video."
category: Commandline_Utilities
requires: $P-libs
category: Libs
requires: msvcrt2019
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	apps \
	bin

cp ../$P-$V/COPYING.LGPLv3 $R/$P-$V-$B.txt

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "A complete, cross-platform solution to record, convert and stream audio and video (development)"
ldesc: "A complete, cross-platform solution to record, convert and stream audio and video (development)"
category: Libs
requires: $P
maintainer: $MAINTAINER
external-source: $P
EOF

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	include \
	lib \
	share/pkgconfig

cp ../$P-$V/COPYING.LGPLv3 $R/$P-devel/$P-devel-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
