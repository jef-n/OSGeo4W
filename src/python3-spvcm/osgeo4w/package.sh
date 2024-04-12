export P=python3-spvcm
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-pandas python3-seaborn python3-numpy python3-libpysal python3-scipy python3-spreg"
export PACKAGES="python3-spvcm"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
