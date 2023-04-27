export P=hdf4
export V=4.2.16
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="libjpeg-turbo-devel zlib-devel szip-devel"

source ../../../scripts/build-helpers

startlog

[ -f hdf-$V.tar.bz2 ] || wget https://support.hdfgroup.org/ftp/HDF/releases/HDF$V/src/hdf-$V.tar.bz2
[ -f ../CMakeLists.txt ] || tar -C .. --xform s,hdf-$V/,, -xjf hdf-$V.tar.bz2

vs2019env
cmakeenv
ninjaenv

mkdir -p build install
cd build

cmake -G Ninja \
	-D CMAKE_BUILD_TYPE=Release \
	-D CMAKE_INSTALL_PREFIX=../install \
	-D HDF4_ENABLE_SZIP_SUPPORT=ON \
       	-D HDF4_BUILD_FORTRAN=OFF \
	-D JPEG_LIBRARY=$(cygpath -aw ../osgeo4w/lib/jpeg.lib) \
	-D JPEG_INCLUDE_DIR=$(cygpath -aw ../osgeo4w/include) \
	-D JPEG_DIR=$(cygpath -aw ../osgeo4w) \
	-D ZLIB_LIBRARY=$(cygpath -aw ../osgeo4w/lib/zlib.lib) \
	-D ZLIB_INCLUDE_DIR=$(cygpath -aw ../osgeo4w/include) \
	-D ZLIB_DIR=$(cygpath -aw ../osgeo4w) \
	-D SZIP_LIBRARY=$(cygpath -aw ../osgeo4w/lib/libszip.lib) \
	-D SZIP_INCLUDE_DIR=$(cygpath -aw ../osgeo4w/include) \
	-D SZIP_DIR=$(cygpath -aw ../osgeo4w) \
	../..
cmake --build .
cmake --install . || cmake --install .

cd ..

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "The HDF4 library for reading and writing HDF4 format (Runtime)"
ldesc: "The HDF4 library for reading and writing HDF4 format (Runtime)"
category: Libs
requires: msvcrt2019 szip libjpeg-turbo zlib
maintainer: $MAINTAINER
EOF

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "The HDF4 library for reading and writing HDF4 format (Development)"
ldesc: "The HDF4 library for reading and writing HDF4 format (Development)"
category: Libs
requires: $P
external-source: $P
maintainer: $MAINTAINER
EOF

cp ../COPYING $R/$P-$V-$B.txt
cp ../COPYING $R/$P-devel/$P-devel-$V-$B.txt

tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	bin/hdf.dll \
	bin/mfhdf.dll \
	bin/xdr.dll

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	cmake include lib

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog


