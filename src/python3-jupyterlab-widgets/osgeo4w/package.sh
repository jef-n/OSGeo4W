export P=python3-jupyterlab-widgets
export V=3.0.15
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools"
export PACKAGES="python3-jupyterlab-widgets"

source ../../../scripts/build-helpers

startlog

# pin 3.0.15 as file names are too long otherwise
packagewheel

endlog
