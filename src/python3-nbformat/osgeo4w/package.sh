export P=python3-nbformat
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-traitlets python3-jupyter-core python3-jsonschema python3-fastjsonschema"
export PACKAGES="python3-nbformat"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
