export P=python3-access
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-scipy python3-sphinx python3-numpy python3-pandas python3-geopandas python3-requests"
export PACKAGES="python3-access"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
