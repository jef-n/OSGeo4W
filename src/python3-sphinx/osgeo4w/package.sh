export P=python3-sphinx
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-babel python3-alabaster python3-packaging python3-snowballstemmer python3-docutils python3-jinja2 python3-imagesize python3-pygments python3-colorama python3-requests"
export PACKAGES="python3-sphinx python3-sphinxcontrib-applehelp python3-sphinxcontrib-devhelp python3-sphinxcontrib-htmlhelp python3-sphinxcontrib-jsmath python3-sphinxcontrib-qthelp python3-sphinxcontrib-serializinghtml"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
