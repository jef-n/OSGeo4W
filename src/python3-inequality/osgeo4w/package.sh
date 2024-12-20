export P=python3-inequality
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-devel python3-numpy python3-scipy python3-geopandas python3-libpysal python3-traitlets python3-matplotlib"
export PACKAGES="python3-inequality"

source ../../../scripts/build-helpers

startlog

packagewheel --only-binary=scipy

endlog
