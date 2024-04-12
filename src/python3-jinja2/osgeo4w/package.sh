export P=python3-jinja2
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-markupsafe"
export PACKAGES="python3-jinja2"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
