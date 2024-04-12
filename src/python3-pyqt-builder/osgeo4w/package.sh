export P=python3-pyqt-builder
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-core python3-pip python3-setuptools python3-wheel python3-sip python3-packaging"
export PACKAGES="python3-pyqt-builder"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
