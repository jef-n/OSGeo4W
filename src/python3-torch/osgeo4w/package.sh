export P=python3-torch
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-mpmath python3-typing-extensions python3-sympy python3-networkx python3-markupsafe python3-filelock python3-jinja2 python3-fsspec"
export PACKAGES="python3-torch"

source ../../../scripts/build-helpers

startlog

packagewheel --only-binary torch

endlog
