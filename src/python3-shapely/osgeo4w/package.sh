export P=python3-shapely
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools geos-devel"

source ../../../scripts/build-helpers

startlog

adddepends=geos packagewheel

endlog
