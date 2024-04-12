export P=python3-sip
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="base python3-core python3-setuptools python3-wheel python3-pip python3-devel python3-packaging python3-toml"
export PACKAGES="python3-sip"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
