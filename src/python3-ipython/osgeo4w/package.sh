export P=python3-ipython
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-prompt-toolkit python3-backcall python3-pygments python3-pickleshare python3-colorama python3-traitlets python3-jedi python3-decorator python3-stack-data python3-matplotlib-inline"
export PACKAGES="python3-ipython"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
