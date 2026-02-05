export P=python3-pyqtwebengine
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-devel python3-pip python3-setuptools python3-sip python3-pyqt5-sip python3-pyqt5 qt5-devel qtwebkit-devel python3-packaging"
export PACKAGES="python3-pyqtwebengine"

source ../../../scripts/build-helpers

startlog

OSGEO4W_PY_INCLUDE_BINARY=1 PIP_NO_BINARY=PyQtWebEngine,PyQtWebEngine-Qt5 adddepends="qt5-libs qt5-devel" packagewheel

endlog
