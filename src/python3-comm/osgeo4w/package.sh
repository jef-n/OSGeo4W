export P=python3-comm
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-traitlets"
export PACKAGES="python3-comm"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
