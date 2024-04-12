export P=python3-spopt
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-scipy python3-scikit-learn python3-numpy python3-pointpats python3-networkx python3-shapely python3-pulp python3-tqdm python3-libpysal python3-spaghetti python3-mapclassify python3-geopandas python3-pandas"
export PACKAGES="python3-spopt"

source ../../../scripts/build-helpers

startlog

# no fortran compiler
packagewheel --only-binary spopt

endlog
