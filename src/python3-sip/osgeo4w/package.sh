export P=python3-sip
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-core python3-pip python3-setuptools python3-wheel"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
