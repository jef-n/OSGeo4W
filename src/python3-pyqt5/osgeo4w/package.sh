export P=python3-pyqt5
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-core python3-pip python3-setuptools python3-wheel python3-devel python3-sip python3-packaging python3-pyqt5-sip python3-pyqt-builder qt5-devel qtwebkit-devel"
export PACKAGES="python3-pyqt5"

source ../../../scripts/build-helpers

startlog

sed -i -e "s#C:/src/osgeo4w/src/qtwebkit/osgeo4w/install#\$\$(OSGEO4W_ROOT)#g" osgeo4w/apps/qt5/mkspecs/modules/*.pri

adddepends="qt5-libs qtwebkit-libs" packagewheel -C --confirm-license= -C --concatenate=10 -C --disable=QtNfc -C --verbose=

endlog
