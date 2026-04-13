export P=python3-pyqt6
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-core python3-pip python3-setuptools python3-wheel python3-devel python3-packaging python3-pyqt6-sip qt6-devel"
export PACKAGES="python3-pyqt6"

source ../../../scripts/build-helpers

startlog

fetchenv osgeo4w/bin/o4w_env.bat
fetchenv osgeo4w/bin/qt6_env.bat

vsenv
cmakeenv
ninjaenv

set | grep "^O4W_QT_" >pip.env
echo "PATH=\"$PATH\"" >>pip.env

OSGEO4W_PY_INCLUDE_BINARY=1 PIP_NO_BINARY=pyqt6 adddepends=qt6-libs packagewheel -C --confirm-license= -C --concatenate=10 -C --verbose=

endlog
