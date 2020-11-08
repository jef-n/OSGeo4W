export P=python3-ipywidgets
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-ipykernel python3-ipython python3-traitlets python3-nbformat python3-widgetsnbextension python3-ipykernel"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
