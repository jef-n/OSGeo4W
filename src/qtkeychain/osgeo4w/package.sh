export P=qtkeychain
export V=0.14.2
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="qt5-devel"
export PACKAGES="qtkeychain-devel qtkeychain-libs"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget -O $P-$V.tar.gz https://github.com/frankosterfeld/$P/archive/refs/tags/$V.tar.gz
[ -f ../$P-$V/CMakeLists.txt ] || tar -C .. -xzf $P-$V.tar.gz

(
	fetchenv osgeo4w/bin/o4w_env.bat
	vsenv
	cmakeenv
	ninjaenv

	mkdir -p build install

	export INSTDIR=$(cygpath -am install)

	export LIB="$LIB;$(cygpath -m $OSGEO4W_ROOT/lib)"
	export INCLUDE="$INCLUDE;$(cygpath -m $OSGEO4W_ROOT/include)"

	cd build

	cmake -G Ninja \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=$INSTDIR/apps/Qt5 \
		../../$P-$V

	cmake --build .
	cmake --install .
	cmakefix $INSTDIR
)

export R=$OSGEO4W_REP/x86_64/release/qt5/$P
mkdir -p $R

for i in devel libs; do
	mkdir -p $R/$P-$i
	cp ../$P-$V/COPYING $R/$P-$i/$P-$i-$V-$B.txt
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
external-source: $P
EOF

tar -C .. -cvjf $R/$P-$V-$B-src.tar.bz2 \
	osgeo4w/package.sh

cd install

tar -cvjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
		apps/Qt5/include/qt5keychain \
		apps/Qt5/lib/*.lib \
		apps/Qt5/lib/cmake/Qt5Keychain \

tar -cvjf $R/$P-libs/$P-libs-$V-$B.tar.bz2 \
		apps/Qt5/share/qt5keychain/translations \
		apps/Qt5/bin

cd ..

endlog
