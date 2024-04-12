export P=python3-argon2-cffi
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-devel python3-setuptools python3-six python3-cffi python3-argon2-cffi-bindings"
export PACKAGES="python3-argon2-cffi"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
