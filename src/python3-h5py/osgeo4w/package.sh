export P=python3-h5py
export V=3.15.1
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-devel python3-numpy python3-six hdf5-devel zlib-devel"
export PACKAGES="python3-h5py"

source ../../../scripts/build-helpers


startlog

p=${P#python3-}
[ -f $p-$V.tar.gz ] || wget https://files.pythonhosted.org/packages/4d/6a/0d79de0b025aa85dc8864de8e97659c94cf3d23148394a954dc5ca52f8c8/$p-$V.tar.gz
[ -d ../$p-$V ] || tar -C .. -xzf $p-$V.tar.gz

fetchenv osgeo4w/bin/o4w_env.bat

vsenv
cmakeenv
ninjaenv

pip3 install "Cython<3.0" pkgconfig

cd ../$p-$V

sed -i -e "/\/home\//d" h5py.egg-info/SOURCES.txt

HDF5_DIR="$(cygpath -aw ../osgeo4w/osgeo4w)" H5PY_SETUP_REQUIRES=0 pip3 install .

OSGEO4W_PY_SKIP_VCHECK=1 OSGEO4W_PY_INCLUDE_BINARY=1 adddepends=hdf5 packagewheel

endlog
