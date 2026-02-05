export P=python3-blosc2
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-numpy python3-numexpr python3-ndindex python3-msgpack python3-requests"
export PACKAGES="python3-blosc2"

source ../../../scripts/build-helpers

startlog

OSGEO4W_PY_INCLUDE_BINARY=1 packagewheel

endlog
