export P=qca-qt6
export V=2.3.8
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="qt6-devel openssl-devel"
export PACKAGES="qca-qt6 qca-qt6-devel"

source ../../../scripts/build-helpers

# doxygen from cygwin

startlog

p=${P%-qt6}
[ -f $p-$V.tar.xz ] || wget https://download.kde.org/stable/$p/$V/$p-$V.tar.xz
[ -f ../$p-$V/CMakeLists.txt ] || tar -C .. -xJf $p-$V.tar.xz
[ -f ../$p-$V/patched ] || {
	patch -d ../$p-$V -p1 --dry-run <qca.diff
	patch -d ../$p-$V -p1 <qca.diff >../$p-$V/patched
}

mkdir -p install build
export INSTDIR=$(cygpath -am install)

(
	vsenv
	cmakeenv
	ninjaenv

	export LIB="$LIB;$(cygpath -am osgeo4w/lib)"
	export INCLUDE="$INCLUDE;$(cygpath -am osgeo4w/include)"

	cd build
	cmake -G Ninja \
		-Wno-dev \
		-D CMAKE_BUILD_TYPE=RelWithDebInfo \
		-D BUILD_WITH_QT6=ON \
		-D QCA_PREFIX_INSTALL_DIR=$INSTDIR/apps/Qt6 \
		-D QCA_PLUGINS_INSTALL_DIR=$INSTDIR/apps/Qt6/plugins/ \
		-D QCA_BINARY_INSTALL_DIR=$INSTDIR/apps/Qt6/bin \
		-D QCA_LIBRARY_INSTALL_DIR=$INSTDIR/apps/Qt6/lib \
		-D QCA_FEATURE_INSTALL_DIR=$INSTDIR/apps/Qt6/mkspecs/features/ \
		-D QCA_INCLUDE_INSTALL_DIR=$INSTDIR/apps/Qt6/include \
		-D QCA_PRIVATE_INCLUDE_INSTALL_DIR=$INSTDIR/apps/Qt6/include \
		-D QCA_DOC_INSTALL_DIR=$INSTDIR/apps/Qt6/doc/html/qca \
		-D QCA_MAN_INSTALL_DIR=$INSTDIR/apps/Qt6/man/ \
		-D BUILD_TESTS=OFF \
		-D PKGCONFIG_INSTALL_PREFIX=$INSTDIR/apps/Qt6/lib/pkgconfig \
		-D CMAKE_SYSTEM_PREFIX_PATH=$(cygpath -am $OSGEO4W_PWD/osgeo4w/apps/Qt6/lib/cmake) \
		../../$p-$V
	cmake --build .
	cmake --install .
	cmakefix $INSTDIR
)

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cp ../$p-$V/COPYING $R/$P-$V-$B.txt
cp ../$p-$V/COPYING $R/$P-devel/$P-$V-$B.txt

cat <<EOF >$R/setup.hint
sdesc: "Qt6 Cryptographic Architecture runtime libraries"
ldesc: "Qt6 Cryptographic Architecture runtime libraries"
maintainer: $MAINTAINER
category: Libs
requires: qt6-libs
EOF

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "Qt6 Cryptographic Architecture headers and libraries (Development)"
ldesc: "Qt6 Cryptographic Architecture headers and libraries (Development)"
maintainer: $MAINTAINER
category: Libs
requires: $P qt6-devel
external-source: $P
EOF

tar -C .. -cvjf $R/$P-$V-$B-src.tar.bz2 \
	osgeo4w/package.sh \
	osgeo4w/qca.diff

cd install

tar -cvjf $R/$P-$V-$B.tar.bz2 \
	apps/Qt6/certs \
	apps/Qt6/bin/*.dll \
	apps/Qt6/bin/*.exe \
	apps/Qt6/plugins/crypto/*.dll \
	apps/Qt6/man/man1/qcatool-qt6.1

tar -cvjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	apps/Qt6/include/QtCrypto \
	apps/Qt6/lib/*.lib \
	apps/Qt6/lib/cmake/

endlog
