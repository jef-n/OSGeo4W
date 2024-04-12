export P=python3-sqlalchemy
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-greenlet python3-typing-extensions"
export PACKAGES="python3-sqlalchemy"

source ../../../scripts/build-helpers

startlog

packagewheel --only-binary Cython

endlog
