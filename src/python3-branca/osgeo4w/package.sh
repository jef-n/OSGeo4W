export P=python3-branca
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-jinja2"
export PACKAGES="python3-branca"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
