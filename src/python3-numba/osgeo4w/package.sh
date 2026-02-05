export P=python3-numba
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-devel python3-numpy python3-llvmlite"
export PACKAGES="python3-numba"

source ../../../scripts/build-helpers

startlog

OSGEO4W_PY_INCLUDE_BINARY=1 PIP_PRE=1 packagewheel

endlog
