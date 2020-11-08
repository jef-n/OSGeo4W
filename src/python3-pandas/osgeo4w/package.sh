export P=python3-pandas
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-numpy python3-pytz python3-python-dateutil"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
