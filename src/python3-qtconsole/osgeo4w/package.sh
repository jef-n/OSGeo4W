export P=python3-qtconsole
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools qt5-devel"

source ../../../scripts/build-helpers

startlog

cat <<EOF >pip.env
export LIB="$(cygpath -am osgeo4w/lib);\$LIB"
export INCLUDE="$(cygpath -am osgeo4w/include);\$INCLUDE"
EOF

packagewheel

endlog
