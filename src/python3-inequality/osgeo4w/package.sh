export P=python3-inequality
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-devel python3-numpy python3-scipy python3-pandas python3-libpysal python3-matplotlib python3-tqdm python3-joblib"
export PACKAGES="python3-inequality"

source ../../../scripts/build-helpers

startlog

OSGEO4W_PY_INCLUDE_BINARY=1 packagewheel

endlog
