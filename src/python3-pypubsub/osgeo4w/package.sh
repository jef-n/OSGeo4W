export P=python3-pypubsub
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools"
export PACKAGES="python3-pypubsub"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
