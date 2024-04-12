export P=python3-jupyter-events
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-referencing python3-jsonschema python3-pyyaml python3-traitlets python3-rfc3339-validator python3-rfc3986-validator python3-python-json-logger"
export PACKAGES="python3-jupyter-events"

source ../../../scripts/build-helpers

startlog

fetchenv osgeo4w/bin/o4w_env.bat

# no rust compiler

pip3 install jupyter-events

packagewheel

endlog
