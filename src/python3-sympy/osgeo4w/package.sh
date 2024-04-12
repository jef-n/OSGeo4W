export P=python3-sympy
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-mpmath"
export PACKAGES="python3-sympy"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
