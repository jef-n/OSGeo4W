export P=python3-netcdf4
export V=1.7.5
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-devel python3-setuptools python3-packaging python3-cftime python3-numpy netcdf-devel hdf5-devel zlib-devel python3-certifi"
export PACKAGES="python3-netcdf4"

source ../../../scripts/build-helpers

startlog

p=${P#python3-}
[ -f $p-$V.tar.gz ] || wget https://files.pythonhosted.org/packages/ca/ef/0f29ed79ddc6dfcdacc03e03c9b5d29c615384353e1f05ee8d2391c62e2b/$p-$V.tar.gz
[ -d ../$p-$V ] || tar -C .. -xzf $p-$V.tar.gz

export HDF5_DIR=$(cygpath -am osgeo4w)
export NETCDF4_DIR=$(cygpath -am osgeo4w)
export LIB="$(cygpath -am osgeo4w/lib);$LIB"
export INCLUDE="$(cygpath -am osgeo4w/include);$INCLUDE"

OSGEO4W_PY_INCLUDE_BINARY=1 PIP_NO_BINARY=netcdf4 adddepends="netcdf hdf5 zlib" packagewheel

endlog
