export P=python3-llvmlite
export V=0.42.0
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools"
export PACKAGES="python3-llvmlite"

source ../../../scripts/build-helpers

startlog

packagewheel --only-binary llvmlite

endlog
