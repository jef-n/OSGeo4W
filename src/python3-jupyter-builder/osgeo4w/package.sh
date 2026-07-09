export P=python3-jupyter-builder
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-jupyter-core python3-traitlets"
export PACKAGES="python3-jupyter-builder"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
