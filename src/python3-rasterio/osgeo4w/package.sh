export P=python3-rasterio
export V=1.3.10
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-devel python3-setuptools python3-affine python3-attrs python3-click python3-cligj python3-numpy python3-snuggs python3-click-plugins gdal-devel python3-certifi"
export PACKAGES="python3-rasterio"

source ../../../scripts/build-helpers

startlog

p=${P#python3-}

[ -f $p-$V.tar.gz ] || wget https://files.pythonhosted.org/packages/26/05/f7c3ee93f270fbd77f7a2d58f2333a21fdf3ef9526a8f0b2a4d5d3d83184/$p-$V.tar.gz
[ -d ../$p-$V ] || tar -C .. -xzf $p-$V.tar.gz

major=$(sed -ne "s/# *define *GDAL_VERSION_MAJOR *//p" osgeo4w/include/gdal_version.h)
minor=$(sed -ne "s/# *define *GDAL_VERSION_MINOR *//p" osgeo4w/include/gdal_version.h)
rev=$(sed -ne "s/# *define *GDAL_VERSION_REV *//p" osgeo4w/include/gdal_version.h)
major=${major%}
minor=${minor%}
rev=${rev%}

export GDAL_VERSION=$major.$minor.$rev
export INCLUDE="$(cygpath -am osgeo4w/include);\$INCLUDE"
export LINK="$(cygpath -am osgeo4w/lib/gdal_i.lib)"

fetchenv osgeo4w/bin/o4w_env.bat

pip3 install ../$p-$V

adddepends="$RUNTIMEDEPENDS" packagewheel

endlog
