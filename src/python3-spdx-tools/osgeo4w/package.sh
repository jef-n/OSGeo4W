export P=python3-spdx-tools
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-ply python3-semantic-version python3-uritools python3-rdflib python3-license-expression python3-click python3-xmltodict python3-pyyaml python3-beartype"
export PACKAGES="python3-spdx-tools"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
