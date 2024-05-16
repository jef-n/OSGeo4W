export P=libiconv
export V=1.17
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none
export PACKAGES="libiconv libiconv-devel"

source ../../../scripts/build-helpers

startlog

[ -f "$P-$V.tar.gz" ] || wget "https://ftp.gnu.org/pub/gnu/$P/$P-$V.tar.gz"
[ -f "configure" ] || tar -C .. -xzf $P-$V.tar.gz

vsenv

cd ../$P-$V

PATH=/bin:$PATH ./configure \
	--host=x86_64-w64-mingw32 \
	--prefix=$OSGEO4W_PWD/install \
	 CC="$PWD/build-aux/compile cl -nologo"   CFLAGS="-MD" \
	CXX="$PWD/build-aux/compile cl -nologo" CXXFLAGS="-MD" CPPFLAGS="-D_WIN32_WINNT=_WIN32_WINNT_WIN8" \
	 AR="$PWD/build-aux/ar-lib lib" \
         NM="dumpbin -symbols" \
	LD="link" \
	STRIP=":" \
	RANLIB=":"

make clean
make
# make check
make install

R=$OSGEO4W_REP/x86_64/release/$P

mkdir -p $R/$P-devel

tar -C $OSGEO4W_PWD/install \
	--exclude "*.3*" \
	-cjf $R/$P-$V-$B.tar.bz2 \
	bin share
cp COPYING $R/$P-$V-$B.txt

cat <<EOF >$R/setup.hint
sdesc: "Codepage translation Library"
ldesc: "Codepage translation Library"
category: Libs
requires: msvcrt2019
maintainer: $MAINTAINER
EOF

tar -C $OSGEO4W_PWD/install \
	-cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	--exclude "*.1*" \
	include lib share

cp COPYING $R/$P-devel/$P-devel-$V-$B.txt

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "Codepage translation Library (Development)"
ldesc: "Codepage translation Library (Development)"
category: Libs
external-source: $P
requires: $P
maintainer: $MAINTAINER
EOF

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
