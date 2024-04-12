export P=python3-statsmodels
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-packaging python3-scipy python3-patsy python3-numpy python3-pandas"
export PACKAGES="python3-statsmodels"

source ../../../scripts/build-helpers

startlog

packagewheel --only-binary statsmodels

endlog
