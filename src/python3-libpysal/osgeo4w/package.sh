export P=python3-libpysal
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-scipy python3-requests python3-jinja2 python3-beautifulsoup4 python3-pandas python3-numpy python3-platformdirs python3-scikit-learn python3-shapely python3-packaging python3-geopandas"
export PACKAGES="python3-libpysal"

source ../../../scripts/build-helpers

startlog

echo unset PIP_NO_BINARY >pip.env

packagewheel

endlog
