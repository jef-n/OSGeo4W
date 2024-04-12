export P=python3-giddy
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-scipy python3-esda python3-mapclassify python3-quantecon python3-libpysal"
export PACKAGES="python3-giddy"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
