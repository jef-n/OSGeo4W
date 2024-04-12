export P=python3-cffi
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-devel python3-pycparser"
export PACKAGES="python3-cffi"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
