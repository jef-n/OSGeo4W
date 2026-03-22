export P=python3-giturlparse
export V=0.12.0
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools"
export PACKAGES="python3-giturlparse"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
