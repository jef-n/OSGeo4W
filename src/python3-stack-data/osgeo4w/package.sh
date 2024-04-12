export P=python3-stack-data
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-asttokens python3-pure-eval python3-executing"
export PACKAGES="python3-stack-data"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
