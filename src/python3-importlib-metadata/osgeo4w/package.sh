export P=python3-importlib-metadata
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-zipp"
export PACKAGES="python3-importlib-metadata"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
