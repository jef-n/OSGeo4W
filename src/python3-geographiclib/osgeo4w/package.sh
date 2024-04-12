export P=python3-geographiclib
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools"
export PACKAGES="python3-geographiclib"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
