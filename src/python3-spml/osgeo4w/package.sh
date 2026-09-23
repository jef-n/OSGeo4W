export P=python3-spml
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-numpy python3-scipy python3-libpysal python3-joblib python3-pandas python3-scikit-learn python3-geopandas"
export PACKAGES="python3-spml"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
