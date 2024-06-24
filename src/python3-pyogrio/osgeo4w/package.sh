export P=python3-pyogrio
export V=0.9.0
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-devel python3-setuptools gdal-devel python3-pyarrow python3-numpy python3-packaging python3-certifi"
export PACKAGES="python3-pyogrio"

source ../../../scripts/build-helpers

startlog

p=${P#python3-}

[ -f $p-$V.tar.gz ] || wget https://files.pythonhosted.org/packages/4e/09/a13ffa71f617f3c76f31984bc4fc237aede9988d89056b278efcb97f6fb0/$p-$V.tar.gz
[ -d ../$p-$V ] || tar -C .. -xzf $p-$V.tar.gz

major=$(sed -ne "s/# *define *GDAL_VERSION_MAJOR *//p" osgeo4w/include/gdal_version.h)
minor=$(sed -ne "s/# *define *GDAL_VERSION_MINOR *//p" osgeo4w/include/gdal_version.h)
rev=$(sed -ne "s/# *define *GDAL_VERSION_REV *//p" osgeo4w/include/gdal_version.h)
major=${major%}
minor=${minor%}
rev=${rev%}

export GDAL_VERSION=$major.$minor.$rev
export GDAL_INCLUDE_PATH="$(cygpath -am osgeo4w/include)"
export GDAL_LIBRARY_PATH="$(cygpath -am osgeo4w/lib)"

fetchenv osgeo4w/bin/o4w_env.bat

pip3 install ../$p-$V

adddepends="$RUNTIMEDEPENDS" packagewheel

endlog
