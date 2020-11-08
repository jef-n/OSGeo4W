export P=python3-pypiwin32
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-pywin32"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
