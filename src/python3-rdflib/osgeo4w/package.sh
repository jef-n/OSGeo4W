export P=python3-rdflib
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pyparsing"
export PACKAGES="python3-rdflib"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
