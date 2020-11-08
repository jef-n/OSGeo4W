export P=python3-numpy
export V=1.19.2+mkl
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools"

source ../../../scripts/build-helpers

startlog

wheel=https://download.lfd.uci.edu/pythonlibs/x2tqcw5k/numpy-$V-cp39-cp39-win_amd64.whl packagewheel

endlog
