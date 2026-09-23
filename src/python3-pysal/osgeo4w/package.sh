export P=python3-pysal
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-scipy python3-tobler python3-giddy python3-spreg python3-mgwr python3-spaghetti python3-spglm python3-access python3-libpysal python3-inequality python3-splot python3-esda python3-spint python3-pointpats python3-mapclassify python3-segregation python3-momepy python3-spopt python3-beautifulsoup4 python3-platformdirs python3-shapely python3-geopandas python3-pandas python3-packaging python3-scikit-learn python3-requests python3-numpy python3-lazy-loader python3-spml"
export PACKAGES="python3-pysal"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
