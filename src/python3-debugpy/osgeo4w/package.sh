export P=python3-debugpy
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-devel"
export PACKAGES="python3-debugpy"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
