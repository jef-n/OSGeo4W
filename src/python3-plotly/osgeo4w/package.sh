export P=python3-plotly
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-retrying python3-six python3-jupyterlab python3-packaging python3-tenacity"
export PACKAGES="python3-plotly"

source ../../../scripts/build-helpers

startlog

packagewheel --only-binary :all:

endlog
