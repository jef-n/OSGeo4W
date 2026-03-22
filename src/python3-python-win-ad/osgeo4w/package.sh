export P=python3-python-win-ad
export V=0.6.2
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-pywin32"
export PACKAGES="python3-python-win-ad"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
