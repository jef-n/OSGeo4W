export P=python3-pum
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-devel python3-packaging python3-pydantic python3-pyyaml python3-psycopg"
export PACKAGES="python3-pum"

source ../../../scripts/build-helpers

echo PIP_NO_BINARY=pum >pip.env

startlog

packagewheel

endlog
