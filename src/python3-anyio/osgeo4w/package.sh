export P=python3-anyio
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-sniffio python3-idna"
export PACKAGES="python3-anyio"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
