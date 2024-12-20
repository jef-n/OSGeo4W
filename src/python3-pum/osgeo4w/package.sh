export P=python3-pum
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-devel python3-psycopg2 python3-pyyaml libpq-devel"
export PACKAGES="python3-pum"

source ../../../scripts/build-helpers

startlog

adddepends=libpq packagewheel

endlog
