export P=python3-widgetsnbextension
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-notebook"
export PACKAGES="python3-widgetsnbextension"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
