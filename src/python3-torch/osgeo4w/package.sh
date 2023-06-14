export P=python3-torch
export V=2.0.1
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-mpmath python3-typing-extensions python3-sympy python3-networkx python3-markupsafe python3-filelock python3-jinja2"

source ../../../scripts/build-helpers

startlog

p=torch-2.0.1-cp39-cp39-win_amd64.whl
curl -LO https://files.pythonhosted.org/packages/48/f4/d0b61525a3d3db78636f1937d1bc24cbb39abc57484a545b72b6ab35c114/$p
wheel=$p packagewheel

endlog
