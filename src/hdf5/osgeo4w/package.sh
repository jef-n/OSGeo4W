export P=hdf5
export V=1.10.7
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="libjpeg-devel szip-devel zlib-devel"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.bz2 ] || wget https://support.hdfgroup.org/ftp/${P^^}/releases/$P-${V%.*}/$P-$V/src/$P-$V.tar.bz2
[ -f ../CMakeLists.txt ] || tar -C .. --xform s,$P-$V/,, -xjf $P-$V.tar.bz2

vs2019env
cmakeenv
ninjaenv

mkdir -p build install
cd build

# C++ and thread-safety options are not supported, override with ALLOW_UNSUPPORTED option
# netcdf requires HDF5_BUILD_HL_LIB

cmake -G Ninja \
	-D CMAKE_BUILD_TYPE=Release \
	-D CMAKE_INSTALL_PREFIX=../install \
	-D HDF5_BUILD_HL_LIB=ON \
	-D BUILD_SHARED_LIBS=ON \
	-D BUILD_STATIC_LIBS=OFF \
	-D HDF5_ENABLE_Z_LIB_SUPPORT=ON \
	-D HDF5_ENABLE_SZIP_SUPPORT=ON \
	-D HDF5_ENABLE_THREADSAFE=ON \
	-D HDF5_BUILD_FORTRAN=OFF \
	-D HDF5_BUILD_HL_LIB=ON \
	-D HDF5_BUILD_CPP_LIB=ON \
	-D ALLOW_UNSUPPORTED=ON \
	-D SZIP_LIBRARY_RELEASE=$(cygpath -aw ../osgeo4w/lib/szip.lib) \
	-D SZIP_INCLUDE_DIR=$(cygpath -aw ../osgeo4w/include) \
	-D SZIP_DIR=$(cygpath -aw ../osgeo4w) \
	-D ZLIB_LIBRARY=$(cygpath -aw ../osgeo4w/lib/zlib.lib) \
	-D ZLIB_INCLUDE_DIR=$(cygpath -aw ../osgeo4w/include) \
	-D HDF5_INSTALL_DATA_DIR=. \
	-D HDF5_INSTALL_CMAKE_DIR=share/cmake \
	../..
ninja
ninja install

cd ..

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-{devel,tools}

cat <<EOF >$R/setup.hint
sdesc: "The HDF5 library for reading and writing HDF5 format (Runtime)"
ldesc: "The HDF5 library for reading and writing HDF5 format (Runtime)"
category: Libs
requires: msvcrt2019 libjpeg szip zlib
maintainer: $MAINTAINER
EOF

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "The HDF5 library for reading and writing HDF5 format (Development)"
ldesc: "The HDF5 library for reading and writing HDF5 format (Development)"
category: Libs
requires: $P-tools
external-source: $P
maintainer: $MAINTAINER
EOF

cat <<EOF >$R/$P-tools/setup.hint
sdesc: "The HDF5 library for reading and writing HDF5 format (Tools)"
ldesc: "The HDF5 library for reading and writing HDF5 format (Tools)"
category: Commandline_Utilities
requires: $P
external-source: $P
maintainer: $MAINTAINER
EOF

cp ../COPYING $R/$P-$V-$B.txt
cp ../COPYING $R/$P-devel/$P-devel-$V-$B.txt
cp ../COPYING $R/$P-tools/$P-tools-$V-$B.txt

tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	bin/hdf5.dll \
	bin/hdf5_cpp.dll \
	bin/hdf5_hl.dll \
	bin/hdf5_hl_cpp.dll \
	bin/hdf5_tools.dll

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	include lib share

tar -C install -cjf $R/$P-tools/$P-tools-$V-$B.tar.bz2 \
	--exclude "*.dll" \
	bin

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
