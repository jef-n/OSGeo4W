export P=python3-momepy
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-scipy python3-shapely python3-libpysal python3-geopandas python3-packaging python3-pandas python3-tqdm python3-networkx"
export PACKAGES="python3-momepy"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
