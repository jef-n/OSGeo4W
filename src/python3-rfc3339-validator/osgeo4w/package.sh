export P=python3-rfc3339-validator
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-six"
export PACKAGES="python3-rfc3339-validator"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
