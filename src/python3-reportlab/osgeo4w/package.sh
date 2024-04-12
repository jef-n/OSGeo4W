export P=python3-reportlab
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-pillow python3-chardet"
export PACKAGES="python3-reportlab"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
