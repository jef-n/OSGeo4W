export P=libiconv
export V=1.16
export B=1
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none

source ../../../scripts/build-helpers

startlog

[ -f "$P-$V.tar.gz" ] || wget "https://ftp.gnu.org/pub/gnu/$P/$P-$V.tar.gz"
[ -f "configure" ] || tar -C .. -xzf $P-$V.tar.gz --xform "s,^$P-$V,.,"

if ! [ -x ar-lib ]; then
	wget -O ar-lib "http://git.savannah.gnu.org/gitweb/?p=automake.git;a=blob_plain;f=lib/ar-lib;hb=HEAD"
	chmod a+x ar-lib
fi

if ! [ -x compile ]; then
	wget -O compile "http://git.savannah.gnu.org/gitweb/?p=automake.git;a=blob_plain;f=lib/compile;hb=HEAD"
	chmod a+x compile
fi

perl -i -pe "s/void libcharset_set_relocation_prefix/void LIBCHARSET_DLL_EXPORTED libcharset_set_relocation_prefix/" ../libcharset/include/libcharset.h

vs2019env

cd ..

if false; then
./configure \
	--host=x86_64-w64-mingw32 \
	--prefix=$OSGEO4W_PWD/install \
	CC="$OSGEO4W_PWD/compile cl -nologo" \
	CFLAGS="-MD" \
	CXX="$OSGEO4W_PWD/compile cl -nologo" \
	CXXFLAGS="-MD" \
	CPPFLAGS="-D_WIN32_WINNT=_WIN32_WINNT_WIN8" \
       	LD="link" \
	NM="dumpbin -symbols" \
	STRIP=":" \
	AR="$OSGEO4W_PWD/ar-lib lib" \
	RANLIB=":"
make clean
fi

# make check
make install

mkdir -p osgeo4w/install/bin

R=$OSGEO4W_REP/x86_64/release/$P

mkdir -p $R/$P-devel

tar -C $OSGEO4W_PWD/install --exclude "*.3.*" -cjf $R/$P-$V-$B.tar.bz2 bin share
cp COPYING $R/$P-$V-$B.txt

cat <<EOF >$R/setup.hint
sdesc: "Codepage translation Library"
ldesc: "Codepage translation Library"
category: Libs
requires: msvcrt2019
maintainer: $MAINTAINER
EOF

tar -C $OSGEO4W_PWD/install --exclude "*.1.*" -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 include lib share
cp COPYING $R/$P-devel/$P-devel-$V-$B.txt

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "Codepage translation Library (Development)"
ldesc: "Codepage translation Library (Development)"
category: Libs
external-source: $P
requires: $P
maintainer: $MAINTAINER
EOF

tar -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
