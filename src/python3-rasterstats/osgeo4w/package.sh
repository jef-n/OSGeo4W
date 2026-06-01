export P=python3-rasterstats
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-affine python3-cligj python3-shapely python3-rasterio python3-simplejson python3-numpy python3-click python3-pyogrio"
export PACKAGES="python3-rasterstats"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
