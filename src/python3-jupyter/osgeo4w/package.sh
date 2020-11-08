export P=python3-jupyter
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-jupyter-console python3-nbconvert python3-ipykernel python3-notebook python3-qtconsole python3-ipywidgets"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
