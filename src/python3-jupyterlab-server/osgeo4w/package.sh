export P=python3-jupyterlab-server
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-maturin python3-jupyter-server python3-requests python3-json5 python3-packaging python3-babel python3-jsonschema python3-jinja2"
export PACKAGES="python3-jupyterlab-server"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
