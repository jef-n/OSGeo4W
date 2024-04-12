export P=python3-jupyter-client
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-traitlets python3-pyzmq python3-python-dateutil python3-tornado python3-jupyter-core"
export PACKAGES="python3-jupyter-client"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
