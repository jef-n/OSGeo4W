export P=python3-nest-asyncio2
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools"
export PACKAGES="python3-nest-asyncio2"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
