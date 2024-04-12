export P=python3-pyyaml
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-core python3-pip python3-wheel python3-setuptools python3-devel"
export PACKAGES="python3-pyyaml"

source ../../../scripts/build-helpers

startlog

packagewheel --only-binary Cython

endlog
