export P=python3-setuptools
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
