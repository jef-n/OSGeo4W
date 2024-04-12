export P=python3-nbclient
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-nbformat python3-nest-asyncio python3-async-generator python3-traitlets python3-jupyter-client python3-jupyter-core"
export PACKAGES="python3-nbclient"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
