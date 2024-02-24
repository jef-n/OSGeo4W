export P=python3-torch
export V=2.2.1
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-mpmath python3-typing-extensions python3-sympy python3-networkx python3-markupsafe python3-filelock python3-jinja2"

source ../../../scripts/build-helpers

startlog

p=torch-$V-cp39-cp39-win_amd64.whl
curl -LO https://files.pythonhosted.org/packages/66/e1/89648ae8f4cb60bb42b59dd991a601abb15a5d1af7ed7dc5989e88e5d3a8/$p
wheel=$p packagewheel

endlog
