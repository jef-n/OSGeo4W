export P=python3-folium
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-jinja2 python3-numpy python3-branca python3-xyzservices python3-requests"
export PACKAGES="python3-folium"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
