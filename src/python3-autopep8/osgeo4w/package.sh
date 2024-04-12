export P=python3-autopep8
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-pycodestyle python3-tomli"
export PACKAGES="python3-autopep8"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
