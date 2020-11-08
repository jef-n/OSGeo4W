export P=python3-pillow
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools zlib-devel libjpeg-devel"

source ../../../scripts/build-helpers

startlog

cp osgeo4w/lib/jpeg_i.lib osgeo4w/lib/jpeg.lib

export INCLUDE="$(cygpath -aw osgeo4w/include);$INCLUDE"
export LIB="$(cygpath -aw osgeo4w/lib);$LIB"

adddepends="zlib libjpeg" packagewheel

endlog
