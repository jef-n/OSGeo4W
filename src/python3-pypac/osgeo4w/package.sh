export P=python3-pypac
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-requests python3-dukpy python3-tldextract"
export PACKAGES="python3-pypac"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
