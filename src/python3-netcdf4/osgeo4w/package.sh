export P=python3-netcdf4
export V=1.6.3
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-devel python3-setuptools python3-cftime python3-numpy netcdf-devel hdf5-devel zlib-devel"

tag=v${V}rel

source ../../../scripts/build-helpers

startlog

[ -f netCDF4-$V.tar.gz ] || wget https://files.pythonhosted.org/packages/8b/92/ff3b18a2f5fe03ffc2807c2ac8b55bee2c8ee730d1100b79bc8a7ab96134/netCDF4-$V.tar.gz
[ -d ../netCDF4-$V ] || tar -C .. -xzf netCDF4-$V.tar.gz

export HDF5_DIR=$(cygpath -am osgeo4w)
export NETCDF4_DIR=$(cygpath -am osgeo4w)
export LIB="$(cygpath -am osgeo4w/lib);$LIB"
export INCLUDE="$(cygpath -am osgeo4w/include);$INCLUDE"

fetchenv osgeo4w/bin/o4w_env.bat

pip3 install ../netCDF4-$V

adddepends="netcdf hdf5 zlib" packagewheel

endlog
