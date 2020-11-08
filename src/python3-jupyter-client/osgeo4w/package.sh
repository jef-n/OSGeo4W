export P=python3-jupyter-client
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
