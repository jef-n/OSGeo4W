export P=python3-tldextract
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-filelock python3-requests-file python3-requests python3-idna"
export PACKAGES="python3-tldextract"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
