export P=python3-owslib
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-pyproj python3-python-dateutil python3-pytz python3-pyyaml python3-requests python3-lxml"
export PACKAGES="python3-owslib"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
