export P=python3-pyogrio
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-devel python3-setuptools gdal-devel python3-pyarrow python3-numpy python3-packaging python3-certifi"
export PACKAGES="python3-pyogrio"

source ../../../scripts/build-helpers

startlog

major=$(sed -ne "s/# *define *GDAL_VERSION_MAJOR *//p" osgeo4w/include/gdal_version.h)
minor=$(sed -ne "s/# *define *GDAL_VERSION_MINOR *//p" osgeo4w/include/gdal_version.h)
rev=$(sed -ne "s/# *define *GDAL_VERSION_REV *//p" osgeo4w/include/gdal_version.h)
major=${major%}
minor=${minor%}
rev=${rev%}

export GDAL_VERSION=$major.$minor.$rev
export GDAL_INCLUDE_PATH="$(cygpath -am osgeo4w/include)"
export GDAL_LIBRARY_PATH="$(cygpath -am osgeo4w/lib)"

OSGEO4W_PY_INCLUDE_BINARY=1 PIP_NO_BINARY=pyogrio adddepends="$RUNTIMEDEPENDS" packagewheel

endlog
