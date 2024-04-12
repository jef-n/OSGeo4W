export P=python3-fiona
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-devel python3-setuptools python3-attrs python3-click python3-cligj python3-click-plugins python3-six python3-munch gdal-devel python3-importlib-metadata python3-certifi"
export PACKAGES="python3-fiona"

source ../../../scripts/build-helpers

startlog

major=$(sed -ne "s/# *define *GDAL_VERSION_MAJOR *//p" osgeo4w/include/gdal_version.h)
minor=$(sed -ne "s/# *define *GDAL_VERSION_MINOR *//p" osgeo4w/include/gdal_version.h)
rev=$(sed -ne "s/# *define *GDAL_VERSION_REV *//p" osgeo4w/include/gdal_version.h)
major=${major%}
minor=${minor%}
rev=${rev%}

cat <<EOF >pip.env
export GDAL_VERSION=$major.$minor.$rev
export INCLUDE="$(cygpath -am osgeo4w/include);\$INCLUDE"
export LINK="$(cygpath -am osgeo4w/lib/gdal_i.lib)"
EOF

fetchenv osgeo4w/bin/o4w_env.bat

adddepends="$RUNTIMEDEPENDS" packagewheel --only-binary Cython

endlog
