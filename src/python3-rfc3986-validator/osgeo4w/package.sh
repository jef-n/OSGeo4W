export P=python3-rfc3986-validator
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools"
export PACKAGES="python3-rfc3986-validator"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
