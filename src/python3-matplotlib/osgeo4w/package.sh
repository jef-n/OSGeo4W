export P=python3-matplotlib
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-pyparsing python3-numpy python3-cycler python3-kiwisolver python3-python-dateutil"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
