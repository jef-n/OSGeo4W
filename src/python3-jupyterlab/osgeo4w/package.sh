export P=python3-jupyterlab
export V=4.1.5
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-async-lru python3-httpx python3-ipykernel python3-jinja2 python3-jupyter-core python3-jupyter-lsp python3-jupyter-server python3-jupyterlab-server python3-notebook-shim python3-packaging python3-tornado python3-traitlets"
export PACKAGES="python3-jupyterlab"

source ../../../scripts/build-helpers

startlog

fetchenv osgeo4w/bin/o4w_env.bat

pip3 install jupyterlab

packagewheel

endlog
