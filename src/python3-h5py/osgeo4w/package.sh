export P=python3-h5py
export V=3.10.0
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-devel python3-numpy python3-six hdf5-devel zlib-devel"
export PACKAGES="python3-h5py"

source ../../../scripts/build-helpers

startlog

p=${P#python3-}
[ -f $p-$V.tar.gz ] || wget https://files.pythonhosted.org/packages/37/fc/0b1825077a1c4c79a13984c59997e4b36702962df0bca420698f77b70b10/$p-$V.tar.gz
[ -d ../$p-$V ] || tar -C .. -xzf $p-$V.tar.gz

fetchenv osgeo4w/bin/o4w_env.bat

vsenv
cmakeenv
ninjaenv

pip3 install "Cython<3.0" pkgconfig

cd ../$p-$V

sed -i -e "/\/home\//d" h5py.egg-info/SOURCES.txt

HDF5_DIR="$(cygpath -aw ../osgeo4w/osgeo4w)" H5PY_SETUP_REQUIRES=0 pip3 install .

adddepends=hdf5 packagewheel

endlog
