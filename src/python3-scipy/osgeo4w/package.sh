export P=python3-scipy
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-numpy"

source ../../../scripts/build-helpers

startlog

wheel=https://download.lfd.uci.edu/pythonlibs/w4tscw6k/scipy-1.6.0-cp39-cp39-win_amd64.whl packagewheel

endlog
