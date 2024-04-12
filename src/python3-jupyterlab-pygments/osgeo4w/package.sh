export P=python3-jupyterlab-pygments
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-pygments"
export PACKAGES="python3-jupyterlab-pygments"

source ../../../scripts/build-helpers

startlog

fetchenv osgeo4w/bin/o4w_env.bat

pip3 install jupyterlab-pygments

packagewheel

endlog
