export P=python3-lxml
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools libxml2-devel libxslt-devel zlib-devel"

source ../../../scripts/build-helpers

startlog

cp osgeo4w/lib/iconv.dll.lib osgeo4w/lib/iconv.lib

cat <<EOF >pip.env
export LIB="$(cygpath -am osgeo4w/lib);\$LIB"
export INCLUDE="$(cygpath -am osgeo4w/include/libxml2);$(cygpath -am osgeo4w/include);\$INCLUDE"
EOF

cp osgeo4w/lib/libxml2.lib osgeo4w/lib/xml2.lib

adddepends="libxml2 libxslt" packagewheel

endlog
