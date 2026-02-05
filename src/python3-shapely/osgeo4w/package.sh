export P=python3-shapely
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-devel python3-setuptools geos-devel python3-numpy"
export PACKAGES="python3-shapely"

source ../../../scripts/build-helpers

startlog

fetchenv osgeo4w/bin/o4w_env.bat

export GEOS_INCLUDE_PATH=$(cygpath -am osgeo4w/include)
export GEOS_LIBRARY_PATH=$(cygpath -am osgeo4w/lib)

OSGEO4W_PY_INCLUDE_BINARY=1 PIP_NO_BINARY=shapely adddepends=geos packagewheel

endlog
