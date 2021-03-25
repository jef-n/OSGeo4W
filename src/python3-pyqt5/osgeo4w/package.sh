export P=python3-pyqt5
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-devel python3-pip python3-setuptools python3-sip python3-pyqt5-sip qt5-devel qtwebkit-devel"

source ../../../scripts/build-helpers

startlog

cat <<EOF >requirements.txt
PyQt5 --global-option="--disable=QtNfc" 
packaging
EOF

# brute force
# FIXME figure out how disabling QtNfc via pip install actually works
rm -rf osgeo4w/apps/qt5/include/QtNfc

adddepends=qt5-libs packagewheel -r requirements.txt

endlog
