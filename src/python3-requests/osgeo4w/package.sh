export P=python3-requests
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-certifi python3-chardet python3-idna python3-urllib3 python3-charset-normalizer"
export PACKAGES="python3-requests"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
