export P=python3-qtconsole
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools qt5-devel python3-jupyter-core python3-ipykernel python3-pyzmq python3-ipython-genutils python3-jupyter-client python3-qtpy python3-pygments python3-traitlets python3-packaging"
export PACKAGES="python3-qtconsole"

source ../../../scripts/build-helpers

startlog

cat <<EOF >pip.env
export LIB="$(cygpath -am osgeo4w/lib);\$LIB"
export INCLUDE="$(cygpath -am osgeo4w/include);\$INCLUDE"
EOF

packagewheel

endlog
