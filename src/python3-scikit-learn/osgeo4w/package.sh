export P=python3-scikit-learn
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-scipy python3-threadpoolctl python3-joblib python3-numpy"
export PACKAGES="python3-scikit-learn"

source ../../../scripts/build-helpers

startlog

# no fortran compiler
packagewheel --only-binary scikit-learn

endlog
