export P=python3-pyserial
export V=pip
export B=pip
export MAINTAINER=Lo
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
