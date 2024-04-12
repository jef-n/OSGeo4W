export P=python3-numba
export V=0.51.2
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-numpy python3-llvmlite"
export PACKAGES="python3-numba"

source ../../../scripts/build-helpers

startlog

wheel=https://files.pythonhosted.org/packages/23/17/fd8fb53210ac5810819da78d011d837bb4293eb597cc2d889c27a5886b5b/numba-0.59.0-cp312-cp312-win_amd64.whl packagewheel

endlog
