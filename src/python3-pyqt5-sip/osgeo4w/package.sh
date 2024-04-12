export P=python3-pyqt5-sip
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-devel python3-pip python3-setuptools python3-sip"
export PACKAGES="python3-pyqt5-sip"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
