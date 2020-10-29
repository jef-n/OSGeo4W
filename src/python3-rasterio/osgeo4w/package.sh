export P=python3-rasterio
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-affine python3-attrs python3-click python3-cligj python3-numpy python3-snuggs python3-click-plugins gdal-devel"

source ../../../scripts/build-helpers

startlog

major=$(sed -ne "s/# *define *GDAL_VERSION_MAJOR *//p" osgeo4w/include/gdal_version.h)
minor=$(sed -ne "s/# *define *GDAL_VERSION_MINOR *//p" osgeo4w/include/gdal_version.h)

cat <<EOF >gdal-config.bat
@echo off
if "%1"=="--libs" echo -L$(cygpath -am osgeo4w/lib) -lgdal_i
if "%1"=="--cflags" echo -I$(cygpath -am osgeo4w/include)
if "%1"=="--version" echo $major.$minor
EOF

cat <<EOF >pip.env
export GDAL_CONFIG=$(cygpath -am gdal-config.bat)
EOF

adddepends="$RUNTIMEDEPENDS" packagewheel

endlog
