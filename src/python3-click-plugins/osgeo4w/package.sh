export P=python3-click-plugins
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-click"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
