export P=python3-jsonschema
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-attrs python3-six python3-pyrsistent python3-referencing python3-rpds-py"
export PACKAGES="python3-jsonschema python3-jsonschema-specifications"

source ../../../scripts/build-helpers

startlog

echo unset PIP_NO_BINARY >pip.env
packagewheel

endlog
