export P=python3-netcdf4
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-cftime python3-numpy netcdf-devel hdf5-devel zlib-devel"

source ../../../scripts/build-helpers

startlog

cat <<EOF >pip.env
export HDF5_DIR=$(cygpath -am osgeo4w)
export NETCDF4_DIR=$(cygpath -am osgeo4w)
export LIB="$(cygpath -am osgeo4w/lib);\$LIB"
export INCLUDE="$(cygpath -am osgeo4w/include);\$INCLUDE"
EOF

adddepends="netcdf hdf5 zlib" packagewheel

endlog
