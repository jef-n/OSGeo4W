export P=python3-spint
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-spreg python3-spglm python3-scipy python3-libpysal python3-numpy"
export PACKAGES="python3-spint"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
