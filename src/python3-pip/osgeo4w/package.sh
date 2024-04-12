export P=python3-pip
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-core"
export PACKAGES="python3-pip"

# initial python3-pip is built from python3

source ../../../scripts/build-helpers

startlog

fetchenv osgeo4w/bin/o4w_env.bat
python3 -m ensurepip
python3 -m pip install --upgrade pip
python3 -m pip install wheel

cat >pip.bat <<EOF
@echo off
pip3 %*
EOF

packagewheel

tar=$OSGEO4W_REP/x86_64/release/python3/$P/$P-$V-$B.tar

bunzip2 $tar.bz2
tar -rf $tar --xform s,^,apps/$PYTHON/Scripts/, pip.bat
bzip2 $tar

endlog
