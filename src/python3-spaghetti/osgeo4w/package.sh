export P=python3-spaghetti
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-numpy python3-pandas python3-esda python3-rtree python3-libpysal python3-scipy"
export PACKAGES="python3-spaghetti"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
