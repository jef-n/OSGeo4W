export P=python3-mod-wsgi
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools apache"

source ../../../scripts/build-helpers

startlog

export MOD_WSGI_APACHE_ROOTDIR=$(cygpath -am osgeo4w/apps/apache)

packagewheel

endlog
