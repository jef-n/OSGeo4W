export P=python3-markdown-it-py
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-mdurl"
export PACKAGES="python3-markdown-it-py"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
