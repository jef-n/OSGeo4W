export P=python3-spglm
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-scipy python3-spreg python3-numpy python3-libpysal"
export PACKAGES="python3-spglm"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
