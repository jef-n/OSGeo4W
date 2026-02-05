export P=python3-notebook-shim
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-maturin python3-jupyter-server"
export PACKAGES="python3-notebook-shim"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
