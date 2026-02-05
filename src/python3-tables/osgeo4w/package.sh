export P=python3-tables
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-devel python3-numpy hdf5-devel python3-httpx python3-py-cpuinfo python3-numexpr python3-blosc2 python3-typing-extensions python3-packaging python3-pyaml"
export PACKAGES="python3-tables"


source ../../../scripts/build-helpers

startlog

OSGEO4W_PY_INCLUDE_BINARY=1 packagewheel

endlog
