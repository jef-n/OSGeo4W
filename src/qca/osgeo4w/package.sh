export P=qca
export V=2.3.8
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="qt5-devel openssl-devel"
export PACKAGES="qca qca-devel"

source ../../../scripts/build-helpers

# doxygen from cygwin

startlog

[ -f $P-$V.tar.xz ] || wget https://download.kde.org/stable/$P/$V/$P-$V.tar.xz
[ -f ../$P-$V/CMakeLists.txt ] || tar -C .. -xJf $P-$V.tar.xz
[ -f ../$P-$V/patched ] || {
	patch -d ../$P-$V -p1 --dry-run <qca.diff
	patch -d ../$P-$V -p1 <qca.diff >../$P-$V/patched
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
		-D QCA_PREFIX_INSTALL_DIR=$INSTDIR/apps/Qt5 \
		-D QCA_PLUGINS_INSTALL_DIR=$INSTDIR/apps/Qt5/plugins/ \
		-D QCA_BINARY_INSTALL_DIR=$INSTDIR/apps/Qt5/bin \
		-D QCA_LIBRARY_INSTALL_DIR=$INSTDIR/apps/Qt5/lib \
		-D QCA_FEATURE_INSTALL_DIR=$INSTDIR/apps/Qt5/mkspecs/features/ \
		-D QCA_INCLUDE_INSTALL_DIR=$INSTDIR/apps/Qt5/include \
		-D QCA_PRIVATE_INCLUDE_INSTALL_DIR=$INSTDIR/apps/Qt5/include \
		-D QCA_DOC_INSTALL_DIR=$INSTDIR/apps/Qt5/doc/html/qca \
		-D QCA_MAN_INSTALL_DIR=$INSTDIR/apps/Qt5/man/ \
		-D BUILD_TESTS=OFF \
		-D PKGCONFIG_INSTALL_PREFIX=$INSTDIR/apps/Qt5/lib/pkgconfig \
		-D CMAKE_SYSTEM_PREFIX_PATH=$(cygpath -am $OSGEO4W_PWD/osgeo4w/apps/Qt5/lib/cmake) \
		../../$P-$V
	cmake --build .
	cmake --install .
	cmakefix $INSTDIR
)

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cp ../$P-$V/COPYING $R/$P-$V-$B.txt
cp ../$P-$V/COPYING $R/$P-devel/$P-$V-$B.txt

cat <<EOF >$R/setup.hint
sdesc: "Qt5 Cryptographic Architecture runtime libraries"
ldesc: "Qt5 Cryptographic Architecture runtime libraries"
maintainer: $MAINTAINER
category: Libs
requires: qt5-libs
EOF

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "Qt5 Cryptographic Architecture headers and libraries (Development)"
ldesc: "Qt5 Cryptographic Architecture headers and libraries (Development)"
maintainer: $MAINTAINER
category: Libs
requires: $P qt5-devel
external-source: $P
EOF

tar -C .. -cvjf $R/$P-$V-$B-src.tar.bz2 \
	osgeo4w/package.sh \
	osgeo4w/qca.diff

cd install

tar -cvjf $R/$P-$V-$B.tar.bz2 \
	apps/Qt5/certs \
	apps/Qt5/bin/*.dll \
	apps/Qt5/bin/*.exe \
	apps/Qt5/plugins/crypto/*.dll \
	apps/Qt5/man/man1/qcatool-qt5.1

tar -cvjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	apps/Qt5/include/QtCrypto \
	apps/Qt5/lib/*.lib \
	apps/Qt5/mkspecs \
	apps/Qt5/lib/cmake/ \

cd ..

endlog
