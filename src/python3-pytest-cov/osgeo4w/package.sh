export P=python3-pytest-cov
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-coverage python3-pytest"
export PACKAGES="python3-pytest-cov"

source ../../../scripts/build-helpers

startlog

echo unset PIP_NO_BINARY >pip.env
packagewheel

endlog
