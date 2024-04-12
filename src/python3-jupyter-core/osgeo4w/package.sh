export P=python3-jupyter-core
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-traitlets python3-pywin32 python3-platformdirs"
export PACKAGES="python3-jupyter-core"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
