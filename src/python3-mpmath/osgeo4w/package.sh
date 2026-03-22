export P=python3-mpmath
export V=1.3.0
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools"
export PACKAGES="python3-mpmath"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
