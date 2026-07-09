export P=python3-notebook
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-tornado python3-jupyter-server python3-jupyterlab python3-jupyterlab-server python3-notebook-shim python3-jupyter-builder"
export PACKAGES="python3-notebook"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
