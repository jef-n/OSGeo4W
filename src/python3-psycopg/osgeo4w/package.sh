export P=python3-psycopg
export V=pip
export B=pip
export MAINTAINER=LoicBartoletti
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-tzdata python3-typing-extensions"
export PACKAGES="python3-psycopg"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
