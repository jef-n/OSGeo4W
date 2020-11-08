export P=python3-pip
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-setuptools python3-wheel"

# initial python3-pip is built from python3

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
