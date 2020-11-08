export P=python3-llvmlite
export V=0.34.0
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools"

source ../../../scripts/build-helpers

startlog

wheel=https://download.lfd.uci.edu/pythonlibs/z2tqcw5k/${P#python3-}-$V-cp39-cp39-win_amd64.whl packagewheel

endlog
