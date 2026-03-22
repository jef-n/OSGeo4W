export P=python3-requests-file
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-requests"
export PACKAGES="python3-requests-file"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
