export P=python3-httpx
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-httpcore python3-certifi python3-sniffio python3-idna python3-anyio"
export PACKAGES="python3-httpx"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
