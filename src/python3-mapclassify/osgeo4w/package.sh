export P=python3-mapclassify
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-scipy python3-networkx python3-scikit-learn python3-pandas python3-numpy"
export PACKAGES="python3-mapclassify"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
