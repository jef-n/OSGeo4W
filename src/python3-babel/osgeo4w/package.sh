export P=python3-babel
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-pytz"
export PACKAGES="python3-babel"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
