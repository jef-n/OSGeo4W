export P=python3-virtualenv
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-six python3-backports.entry-points-selectable python3-filelock python3-platformdirs python3-distlib"
export PACKAGES="python3-virtualenv"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
