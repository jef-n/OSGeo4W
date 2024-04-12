export P=hdf4
export V=4.3.0
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="libjpeg-turbo-devel zlib-devel szip-devel"
export PACKAGES="hdf4 hdf4-devel hdf4-tools"

source ../../../scripts/build-helpers

startlog


p=${P%4}
[ -f $p$V.tar.gz ] || wget https://github.com/HDFGroup/$P/archive/refs/tags/$p$V.tar.gz
[ -f ../$P-$p$V/CMakeLists.txt ] || tar -C .. -xzf $p$V.tar.gz

vsenv
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
	-D SZIP_LIBRARIES=$(cygpath -aw ../osgeo4w/lib/libszip.lib) \
	-D SZIP_INCLUDE_DIR=$(cygpath -aw ../osgeo4w/include) \
	-D SZIP_DIR=$(cygpath -aw ../osgeo4w) \
	../../$P-$p$V
cmake --build .
cmake --install . || cmake --install .
cmakefix ../install

cd ..

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-{devel,tools}

cat <<EOF >$R/setup.hint
sdesc: "The HDF4 library for reading and writing HDF4 format (Runtime)"
ldesc: "The HDF4 library for reading and writing HDF4 format (Runtime)"
category: Libs
requires: msvcrt2019 szip libjpeg-turbo zlib
maintainer: $MAINTAINER
EOF

cat <<EOF >$R/$P-tools/setup.hint
sdesc: "The HDF4 library for reading and writing HDF4 format (Tools)"
ldesc: "The HDF4 library for reading and writing HDF4 format (Tools)"
category: Libs
requires: $P
external-source: $P
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

cp ../$P-$p$V/COPYING $R/$P-$V-$B.txt
cp ../$P-$p$V/COPYING $R/$P-devel/$P-devel-$V-$B.txt
cp ../$P-$p$V/COPYING $R/$P-tools/$P-tools-$V-$B.txt

tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	bin/hdf.dll \
	bin/mfhdf.dll

tar -C install -cjf $R/$P-tools/$P-tools-$V-$B.tar.bz2 \
	bin/hdfed.exe \
	bin/hdfimport.exe \
	bin/hdfls.exe \
	bin/hdiff.exe \
	bin/hdp.exe \
	bin/hrepack.exe \
	bin/ncdump.exe \
	bin/ncgen.exe

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	cmake include lib

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
