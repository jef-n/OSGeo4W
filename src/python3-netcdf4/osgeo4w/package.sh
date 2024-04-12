export P=python3-netcdf4
export V=1.6.5
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-devel python3-setuptools python3-cftime python3-numpy netcdf-devel hdf5-devel zlib-devel python3-certifi"
export PACKAGES="python3-netcdf4"

source ../../../scripts/build-helpers

startlog

[ -f netCDF4-$V.tar.gz ] || wget https://files.pythonhosted.org/packages/da/f2/b7307966bf174559c80c0bdaaccebe1538efa3aef8e996d18229b01e9760/netCDF4-1.6.5.tar.gz
[ -d ../netCDF4-$V ] || tar -C .. -xzf netCDF4-$V.tar.gz

export HDF5_DIR=$(cygpath -am osgeo4w)
export NETCDF4_DIR=$(cygpath -am osgeo4w)
export LIB="$(cygpath -am osgeo4w/lib);$LIB"
export INCLUDE="$(cygpath -am osgeo4w/include);$INCLUDE"

fetchenv osgeo4w/bin/o4w_env.bat

pip3 install ../netCDF4-$V

adddepends="netcdf hdf5 zlib" packagewheel

endlog
