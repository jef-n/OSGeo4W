export P=python3-jupyter-server-terminals
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-maturin python3-pywinpty python3-terminado"
export PACKAGES="python3-jupyter-server-terminals"

source ../../../scripts/build-helpers

startlog

fetchenv osgeo4w/bin/o4w_env.bat

pip3 install jupyter-server-terminals

packagewheel

endlog
