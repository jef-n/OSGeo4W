export P=python3-pywinpty
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools"
export PACKAGES="python3-pywinpty"

source ../../../scripts/build-helpers

startlog

# no rust compiler
packagewheel --only-binary pywinpty

endlog
