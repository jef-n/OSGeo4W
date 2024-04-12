export P=python3-pythonqwt
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-numpy python3-pyqt5 python3-qtpy"
export PACKAGES="python3-pythonqwt"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
