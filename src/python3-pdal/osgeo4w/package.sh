export P=python3-pdal
export V=3.2.3
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-devel python3-setuptools python3-numpy python3-pybind11 python3-packaging python3-pyparsing pdal-devel"
export PACKAGES="python3-pdal"

source ../../../scripts/build-helpers

startlog

cd ..

if [ -d pdalextension ]; then
	cd pdalextension
	git fetch
else
	git clone https://github.com/PDAL/python pdalextension
	cd pdalextension
fi

git checkout $V

cd $OSGEO4W_PWD

fetchenv osgeo4w/bin/o4w_env.bat

vsenv
cmakeenv
ninjaenv

pip3 install scikit_build

cat <<EOF >pip.env
EOF

export INCLUDE="$(cygpath -am osgeo4w/include);\$INCLUDE"
export LIB="$(cygpath -am osgeo4w/lib);\$LIB"
export CMAKE_PREFIX_PATH="$(cygpath -am osgeo4w/apps/$PYTHON/Lib/site-packages/pybind11)"

cd ../pdalextension

pip3 install .

adddepends=pdal packagewheel $(cygpath -am $PWD)

endlog
