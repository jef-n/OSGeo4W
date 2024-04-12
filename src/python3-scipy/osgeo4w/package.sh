export P=python3-scipy
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-numpy"
export PACKAGES="python3-scipy"

source ../../../scripts/build-helpers

startlog

packagewheel --only-binary scipy

endlog
