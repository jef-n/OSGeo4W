export P=python3-prompt-toolkit
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-wcwidth"
export PACKAGES="python3-prompt-toolkit"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
