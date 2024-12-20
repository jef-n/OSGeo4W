export P=python3-splot
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-libpysal python3-mapclassify python3-numpy python3-spreg python3-matplotlib python3-esda python3-giddy python3-seaborn python3-geopandas python3-descartes python3-packaging"
export PACKAGES="python3-splot"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
