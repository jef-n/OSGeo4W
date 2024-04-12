export P=python3-httpcore
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-certifi python3-h11"
export PACKAGES="python3-httpcore"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
