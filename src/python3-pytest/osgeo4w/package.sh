export P=python3-pytest
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-packaging python3-toml python3-iniconfig python3-atomicwrites python3-attrs python3-py python3-colorama python3-pluggy"
export PACKAGES="python3-pytest"

source ../../../scripts/build-helpers

startlog

echo unset PIP_NO_BINARY >pip.env

packagewheel

endlog
