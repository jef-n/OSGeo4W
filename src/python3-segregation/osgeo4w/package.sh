export P=python3-segregation
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-devel python3-matplotlib python3-numpy python3-libpysal python3-mapclassify python3-tqdm python3-scipy python3-scikit-learn python3-geopandas python3-pandas python3-seaborn python3-llvmlite python3-deprecation python3-joblib python3-pyproj python3-numba"
export PACKAGES="python3-segregation"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
