export P=python3-jupyter
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-packaging python3-ipykernel python3-ipywidgets python3-jupyter-console python3-nbconvert python3-notebook python3-qtconsole python3-jupyterlab"
export PACKAGES=python3-jupyter

source ../../../scripts/build-helpers

startlog

packagewheel --only-binary jupyter

endlog
