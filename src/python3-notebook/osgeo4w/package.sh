export P=python3-notebook
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-jupyter-core python3-jinja2 python3-nbconvert python3-traitlets python3-argon2-cffi python3-terminado python3-nbformat python3-tornado python3-pyzmq python3-ipython-genutils python3-ipykernel python3-jupyter-client python3-send2trash python3-prometheus-client python3-jupyter-server python3-jupyterlab python3-jupyterlab-server python3-notebook-shim"
export PACKAGES="python3-notebook"

source ../../../scripts/build-helpers

startlog

fetchenv osgeo4w/bin/o4w_env.bat

pip3 install notebook

packagewheel

endlog
