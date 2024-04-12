export P=python3-quantecon
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-requests python3-scipy python3-numba python3-sympy python3-numpy"
export PACKAGES="python3-quantecon"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
