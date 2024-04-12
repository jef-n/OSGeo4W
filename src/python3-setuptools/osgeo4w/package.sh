export P=python3-setuptools
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-devel"
export PACKAGES="python3-setuptools"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
