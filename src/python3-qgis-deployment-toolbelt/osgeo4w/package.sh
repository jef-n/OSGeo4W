export P=python3-qgis-deployment-toolbelt
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-truststore python3-dulwich python3-python-win-ad python3-pywin32 python3-packaging python3-pypac python3-pyyaml python3-requests python3-python-rule-engine python3-imagesize python3-giturlparse"
export PACKAGES="python3-qgis-deployment-toolbelt"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
