export P=python3-pointpats
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-scipy python3-matplotlib python3-pandas python3-numpy python3-libpysal"
export PACKAGES="python3-pointpats"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
