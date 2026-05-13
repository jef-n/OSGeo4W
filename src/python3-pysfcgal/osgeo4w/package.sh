export P=python3-pysfcgal
export V=pip
export B=pip
export MAINTAINER=JeanFelder
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-devel python3-cffi sfcgal"
export PACKAGES="python3-pysfcgal"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
