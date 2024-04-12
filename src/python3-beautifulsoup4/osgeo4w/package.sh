export P=python3-beautifulsoup4
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-soupsieve"
export PACKAGES="python3-beautifulsoup4"

source ../../../scripts/build-helpers

startlog

echo unset PIP_NO_BINARY >pip.env
packagewheel

endlog
