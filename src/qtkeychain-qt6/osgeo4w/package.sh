export P=qtkeychain-qt6
export V=0.14.2
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="qt6-devel"
export PACKAGES="qtkeychain-qt6-devel qtkeychain-qt6-libs"

source ../../../scripts/build-helpers

startlog

p=${P%-qt6}
[ -f $p-$V.tar.gz ] || wget -O $p-$V.tar.gz https://github.com/frankosterfeld/$p/archive/refs/tags/$V.tar.gz
[ -f ../$p-$V/CMakeLists.txt ] || tar -C .. -xzf $p-$V.tar.gz

(
	echo PATH0:$PATH
	fetchenv osgeo4w/bin/o4w_env.bat
	echo PATH1:$PATH
	fetchenv osgeo4w/bin/qt6_env.bat
	echo PATH2:$PATH

	vsenv
	cmakeenv
	ninjaenv

	mkdir -p build install

	export INSTDIR=$(cygpath -am install)

	export LIB="$LIB;$(cygpath -m $OSGEO4W_ROOT/lib)"
	export INCLUDE="$INCLUDE;$(cygpath -m $OSGEO4W_ROOT/include)"

	echo FINAL PATH:$PATH
	type -a qtpaths.exe
	qtpaths.exe --query QT_INSTALL_PREFIX

	cd build

	cmake -G Ninja \
		-DCMAKE_BUILD_TYPE=Release \
		-DBUILD_WITH_QT6=ON \
		-DCMAKE_INSTALL_PREFIX=$INSTDIR/apps/Qt6 \
		../../$p-$V

	cmake --build .
	cmake --install .
	cmakefix $INSTDIR
)

export R=$OSGEO4W_REP/x86_64/release/qt6/$P
mkdir -p $R

for i in devel libs; do
	mkdir -p $R/$P-$i
	cp ../$p-$V/COPYING $R/$P-$i/$P-$i-$V-$B.txt
done

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "Platform-independent Qt API for storing passwords securely. (Development)"
ldesc: "Platform-independent Qt API for storing passwords securely. (Development)"
maintainer: $MAINTAINER
category: Libs
requires: qt6-devel qt6-libs $P-libs
external-source: $P
EOF

cat <<EOF >$R/$P-libs/setup.hint
sdesc: "Platform-independent Qt API for storing passwords securely."
ldesc: "Platform-independent Qt API for storing passwords securely."
maintainer: $MAINTAINER
category: Libs
requires: qt6-libs
external-source: $P
EOF

tar -C .. -cvjf $R/$P-$V-$B-src.tar.bz2 \
	osgeo4w/package.sh

cd install

tar -cvjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
		apps/Qt6/include/qt6keychain \
		apps/Qt6/lib/*.lib \
		apps/Qt6/lib/cmake/Qt6Keychain \

tar -cvjf $R/$P-libs/$P-libs-$V-$B.tar.bz2 \
		apps/Qt6/share/qt6keychain/translations \
		apps/Qt6/bin

cd ..

endlog
