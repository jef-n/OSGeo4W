export P=python3-pyaml
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-pyyaml"
export PACKAGES="python3-pyaml"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
