export P=python3-pyproj
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-devel proj-devel python3-certifi"
export PACKAGES="python3-pyproj"

source ../../../scripts/build-helpers

startlog

OSGEO4W_PY_INCLUDE_BINARY=1 PIP_NO_BINARY=pyproj adddepends="$RUNTIMEDEPENDS" packagewheel

endlog
