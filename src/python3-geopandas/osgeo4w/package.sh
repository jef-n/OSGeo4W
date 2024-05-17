export P=python3-geopandas
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-pandas python3-pyproj python3-shapely python3-fiona python3-packaging python3-numpy"
export PACKAGES="python3-geopandas"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
