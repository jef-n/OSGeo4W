export P=python3-pyserial
export V=pip
export B=pip
export MAINTAINER=Lo
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools"
export PACKAGES="python3-pyserial"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
