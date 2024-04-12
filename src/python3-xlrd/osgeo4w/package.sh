export P=python3-xlrd
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools"
export PACKAGES="python3-xlrd"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
