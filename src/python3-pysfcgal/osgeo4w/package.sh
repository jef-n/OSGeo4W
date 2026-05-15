export P=python3-pysfcgal
export V=pip
export B=pip
export MAINTAINER=JeanFelder
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-devel python3-cffi sfcgal-devel"
export PACKAGES="python3-pysfcgal"

source ../../../scripts/build-helpers

startlog

export LIB="$(cygpath -am osgeo4w/lib);$LIB"
export INCLUDE="$(cygpath -am osgeo4w/include);$INCLUDE"

OSGEO4W_PY_INCLUDE_BINARY=1 PIP_NO_BINARY=pysfcgal adddepends=sfcgal packagewheel

endlog
