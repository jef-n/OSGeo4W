export P=python3-win-ad
export V=0.6.2
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools"
export PACKAGES="python3-win-ad"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
