export P=python3-formulaic
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-scipy python3-numpy python3-pandas python3-wrapt python3-interface-meta python3-typing-extensions python3-narwhals"
export PACKAGES="python3-formulaic"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
