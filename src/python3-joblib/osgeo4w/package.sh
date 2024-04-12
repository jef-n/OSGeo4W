export P=python3-joblib
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools"
export PACKAGES="python3-joblib"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
