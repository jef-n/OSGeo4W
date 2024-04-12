export P=python3-tobler
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-scipy python3-geopandas python3-pandas python3-rasterio python3-rasterstats python3-numpy python3-statsmodels python3-tqdm python3-libpysal python3-joblib"
export PACKAGES="python3-tobler"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
