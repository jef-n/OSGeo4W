export P=python3-kiwisolver
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-devel"
export PACKAGES="python3-kiwisolver"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
