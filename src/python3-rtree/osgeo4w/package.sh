export P=python3-rtree
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools libspatialindex-devel"

source ../../../scripts/build-helpers

startlog

export INCLUDE="$(cygpath -aw osgeo4w/include);$INCLUDE"
export LIB="$(cygpath -aw osgeo4w/lib);$LIB"

adddepends="libspatialindex" packagewheel

endlog
