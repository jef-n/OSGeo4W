export P=python3-pirogue
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-devel python3-psycopg2 python3-pyyaml libpq-devel"
export PACKAGES="python3-pirogue"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
