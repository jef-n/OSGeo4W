export P=python3-spreg
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-scipy python3-libpysal python3-pandas python3-numpy python3-scikit-learn"
export PACKAGES="python3-spreg"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
