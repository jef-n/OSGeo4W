export P=python3-qtpy
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-packaging"
export PACKAGES="python3-qtpy"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
