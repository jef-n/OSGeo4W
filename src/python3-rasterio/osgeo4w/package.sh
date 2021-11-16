export P=python3-rasterio
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-affine python3-attrs python3-click python3-cligj python3-numpy python3-snuggs python3-click-plugins gdal-devel"

source ../../../scripts/build-helpers

startlog

major=$(sed -ne "s/# *define *GDAL_VERSION_MAJOR *//p" osgeo4w/include/gdal_version.h)
minor=$(sed -ne "s/# *define *GDAL_VERSION_MINOR *//p" osgeo4w/include/gdal_version.h)

cat <<EOF >pip.env
export GDAL_VERSION=$major.$minor
export INCLUDE="$(cygpath -am osgeo4w/include);\$INCLUDE"
export LINK="$(cygpath -am osgeo4w/lib/gdal_i.lib)"
export PIP_USE_PEP517=0
EOF

adddepends="$RUNTIMEDEPENDS" packagewheel

endlog
