export P=python3-scikit-learn
export V=0.23.2
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools"

source ../../../scripts/build-helpers

startlog

p=${P#python3-}
p=${p//-/_}
wheel=https://download.lfd.uci.edu/pythonlibs/z2tqcw5k/$p-$V-cp39-cp39-win_amd64.whl packagewheel

endlog
