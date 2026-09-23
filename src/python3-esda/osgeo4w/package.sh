export P=python3-esda
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-pandas python3-libpysal python3-scikit-learn python3-scipy python3-shapely python3-geopandas python3-numpy"
export PACKAGES="python3-esda"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
