export P=python3-ipyleaflet
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-traittypes python3-branca python3-xyzservices python3-ipywidgets python3-jupyter-leaflet"
export PACKAGES=python3-ipyleaflet

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
