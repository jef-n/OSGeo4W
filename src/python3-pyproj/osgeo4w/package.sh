export P=python3-pyproj
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-devel proj-devel python3-certifi"
export PACKAGES="python3-pyproj"

source ../../../scripts/build-helpers

startlog

adddepends="$RUNTIMEDEPENDS" packagewheel --only-binary Cython

endlog
