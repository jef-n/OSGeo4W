export P=python3-nbconvert
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-pandocfilters python3-nbformat python3-pygments python3-testpath python3-jinja2 python3-traitlets python3-entrypoints python3-mistune python3-jupyterlab-pygments python3-jupyter-core python3-bleach python3-nbclient python3-defusedxml python3-markupsafe python3-tinycss2 python3-beautifulsoup4 python3-packaging"
export PACKAGES="python3-nbconvert"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
