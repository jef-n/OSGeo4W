export P=python3-license-expression
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-boolean-py"
export PACKAGES="python3-license-expression"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
