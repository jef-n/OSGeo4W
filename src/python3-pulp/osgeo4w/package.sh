export P=python3-pulp
export V=3.3.2
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools"
export PACKAGES="python3-pulp"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
