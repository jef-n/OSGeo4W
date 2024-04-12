export P=python3-remotior-sensus
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-numpy python3-gdal python3-scipy python3-matplotlib"
export PACKAGES="python3-remotior-sensus"

source ../../../scripts/build-helpers

startlog

cat <<EOF >pip.env
export PIP_USE_PEP517=0
EOF

fetchenv osgeo4w/bin/o4w_env.bat

pip3 install ${P#python3-}

adddepends="python3-numpy python3-scipy python3-gdal python3-matplotlib" packagewheel

endlog
