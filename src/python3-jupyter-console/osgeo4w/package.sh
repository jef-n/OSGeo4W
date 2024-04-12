export P=python3-jupyter-console
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-jupyter-client python3-ipython python3-pygments python3-ipykernel python3-prompt-toolkit python3-jupyter-core python3-pyzmq python3-traitlets"
export PACKAGES="python3-jupyter-console"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
