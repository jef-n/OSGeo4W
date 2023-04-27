export P=python3-h5py
export V=3.8.0
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-devel python3-wheel python3-setuptools python3-numpy python3-six hdf5-devel"

source ../../../scripts/build-helpers

startlog

[ -f h5py-$V.tar.gz ] || wget https://files.pythonhosted.org/packages/69/f4/3172bb63d3c57e24aec42bb93fcf1da4102752701ab5ad10b3ded00d0c5b/h5py-$V.tar.gz
[ -d ../h5py-$V ] || tar -C .. -xzf h5py-$V.tar.gz

export LIB="$(cygpath -am osgeo4w/lib);$LIB"
export INCLUDE="$(cygpath -am osgeo4w/include);$INCLUDE"

fetchenv osgeo4w/bin/o4w_env.bat

pip3 install ../h5py-$V

adddepends=netcdf packagewheel

endlog
