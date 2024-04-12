export P=python3-patsy
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-six python3-numpy"
export PACKAGES="python3-patsy"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
