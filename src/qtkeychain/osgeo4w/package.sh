export P=qtkeychain
export V=0.13.2
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="qt5-devel"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget -O $P-$V.tar.gz https://github.com/frankosterfeld/$P/archive/v$V.tar.gz
[ -f ../$P-$V/CMakeLists.txt ] || tar -C .. -xzf $P-$V.tar.gz

(
	fetchenv osgeo4w/bin/o4w_env.bat
	vs2019env
	cmakeenv
	ninjaenv

	mkdir -p build install

	export INSTDIR=$(cygpath -am install)

	export LIB="$LIB;$(cygpath -m $OSGEO4W_ROOT/lib)"
	export INCLUDE="$INCLUDE;$(cygpath -m $OSGEO4W_ROOT/include)"

	cd build

	cmake -G Ninja \
		-DCMAKE_BUILD_TYPE=Release \
		-DQT_TRANSLATIONS_DIR=$INSTDIR/apps/Qt5/translations \
		-DCMAKE_INSTALL_BINDIR=$INSTDIR/apps/Qt5/bin \
		-DCMAKE_INSTALL_LIBDIR=$INSTDIR/apps/Qt5/lib \
		-DCMAKE_INSTALL_INCLUDEDIR=$INSTDIR/apps/Qt5/include \
		-DPKGCONFIG_INSTALL_PREFIX=$INSTDIR/apps/Qt5/lib/pkgconfig \
		../../$P-$V

	cmake --build .
	cmake --install .
)

export R=$OSGEO4W_REP/x86_64/release/qt5/$P
mkdir -p $R

for i in devel libs; do
	mkdir -p $R/$P-$i
	cp ../$P-$V/COPYING $R/$P-$i
done

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "Platform-independent Qt API for storing passwords securely. (Development)"
ldesc: "Platform-independent Qt API for storing passwords securely. (Development)"
maintainer: $MAINTAINER
category: Libs
requires: qt5-devel qt5-libs $P-libs
external-source: $P
EOF

cat <<EOF >$R/$P-libs/setup.hint
sdesc: "Platform-independent Qt API for storing passwords securely."
ldesc: "Platform-independent Qt API for storing passwords securely."
maintainer: $MAINTAINER
category: Libs
requires: qt5-libs
EOF

tar -C .. -cvjf $R/$P-$V-$B-src.tar.bz2 \
	osgeo4w/package.sh

cd install

tar -cvjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
		apps/Qt5/include/qt5keychain \
		apps/Qt5/lib/*.lib \
		apps/Qt5/lib/cmake/Qt5Keychain \

tar -cvjf $R/$P-libs/$P-libs-$V-$B.tar.bz2 \
		apps/Qt5/translations \
		apps/Qt5/bin

cd ..

endlog
