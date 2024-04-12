export P=python3-backports.entry-points-selectable
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools"
export PACKAGES="python3-backports.entry-points-selectable"

source ../../../scripts/build-helpers

startlog

echo unset PIP_NO_BINARY >pip.env
packagewheel

endlog
