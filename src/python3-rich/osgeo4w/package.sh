export P=python3-rich
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-pygments python3-markdown-it-py"
export PACKAGES="python3-rich"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
