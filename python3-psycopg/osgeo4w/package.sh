export P=python3-psycopg
export V=pip
export B=pip
export MAINTAINER=LoicBartoletti
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
