export P=python3-pyqtwebengine
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-devel python3-pip python3-setuptools python3-sip python3-pyqt5-sip python3-pyqt5 qt5-devel qtwebkit-devel python3-packaging"

source ../../../scripts/build-helpers

startlog

cat <<EOF >pip.env
export PIP_NO_DEPENDENCIES=0
EOF

adddepends=qt5-webengine packagewheel

endlog
