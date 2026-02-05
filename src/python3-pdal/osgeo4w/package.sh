export P=python3-pdal
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-devel python3-numpy python3-pybind11 python3-packaging python3-pyparsing pdal-devel"
export PACKAGES="python3-pdal"

source ../../../scripts/build-helpers

startlog

fetchenv osgeo4w/bin/o4w_env.bat

pip3 install scikit_build

export INCLUDE="$(cygpath -am osgeo4w/include);\$INCLUDE"
export LIB="$(cygpath -am osgeo4w/lib);\$LIB"
export CMAKE_PREFIX_PATH="$(cygpath -am osgeo4w/apps/$PYTHON/Lib/site-packages/pybind11)"
export CXXFLAGS="-DPDAL_DLL=PDAL_EXPORT $CXXFLAGS"

OSGEO4W_PY_INCLUDE_BINARY=1 PIP_NO_BINARY=pdal adddepends=pdal packagewheel 

endlog
