export P=python3-munch
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-six"
export PACKAGES="python3-munch"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
