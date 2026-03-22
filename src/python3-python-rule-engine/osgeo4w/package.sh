export P=python3-python-rule-engine
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-pydantic python3-pydantic-core python3-jsonpath-ng"
export PACKAGES="python3-python-rule-engine"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
