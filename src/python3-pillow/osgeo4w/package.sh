export P=python3-pillow
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-devel python3-setuptools zlib-devel libjpeg-turbo-devel libtiff-devel freetype-devel"

source ../../../scripts/build-helpers

startlog

export INCLUDE="$(cygpath -aw osgeo4w/include);$INCLUDE"
export LIB="$(cygpath -aw osgeo4w/lib);$LIB"

adddepends="zlib libjpeg-turbo libtiff freetype" packagewheel

endlog
