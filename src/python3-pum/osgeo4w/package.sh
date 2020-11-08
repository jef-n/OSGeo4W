export P=python3-pum
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-psycopg2-binary python3-pyyaml"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
