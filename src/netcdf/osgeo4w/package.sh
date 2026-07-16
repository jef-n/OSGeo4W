export P=netcdf
export V=4.10.1
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="hdf4-devel hdf5-devel curl-devel zlib-devel hdf5-tools libaec-devel zstd-devel libxml2-devel c-blosc-devel libjpeg-turbo-devel"
export PACKAGES="netcdf netcdf-devel netcdf-tools"

source ../../../scripts/build-helpers

startlog

[ -f $P-c-$V.tar.gz ] || wget https://downloads.unidata.ucar.edu/$P-c/$V/$P-c-$V.tar.gz
[ -f ../$P-c-$V/CMakeLists.txt ] || tar -C .. -xzf $P-c-$V.tar.gz

vsenv
cmakeenv
ninjaenv

mkdir -p build install
cd build

cmake -G Ninja \
	-D CMAKE_BUILD_TYPE=Release \
	-D CMAKE_INSTALL_PREFIX=$(cygpath -aw ../install) \
	-D CMAKE_INCLUDE_PATH=$(cygpath -aw ../osgeo4w/include) \
	-D HDF4_ROOT_DIR_HINT=$(cygpath -am ../osgeo4w/share/cmake) \
	-D HDF5_DIR=$(cygpath -am ../osgeo4w/share/cmake) \
	-D HDF5_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D CURL_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D CURL_LIBRARY=$(cygpath -am ../osgeo4w/lib/libcurl_imp.lib) \
	-D ZSTD_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D ZSTD_LIBRARY=$(cygpath -am ../osgeo4w/lib/zstd.lib) \
	-D LIBXML2_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include/libxml2) \
	-D LIBXML2_LIBRARY=$(cygpath -am ../osgeo4w/lib/libxml2.lib) \
	-D ZLIB_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
	-D Szip_ROOT=$(cygpath -am ../osgeo4w) \
	-D Blosc_ROOT=$(cygpath -am ../osgeo4w) \
	-D NETCDF_ENABLE_HDF4=ON \
	-D HDF4_ROOT=$(cygpath -am ../osgeo4w) \
	-D NETCDF_ENABLE_MMAP=OFF \
	-D NETCDF_ENABLE_EXAMPLES=OFF \
	-D PACKAGE_PREFIX_DIR=$(cygpath -am ../osgeo4w/cmake) \
	../../$P-c-$V
cmake --build .
cmake --build . --target install
cmakefix ../install

cd ..

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-{devel,tools}

cat <<EOF >$R/setup.hint
sdesc: "The NetCDF library and commands for reading and writing NetCDF format (Runtime)"
ldesc: "The NetCDF library and commands for reading and writing NetCDF format (Runtime)"
category: Libs
requires: base hdf4 hdf5 curl zlib libaec c-blosc libjpeg-turbo
maintainer: $MAINTAINER
EOF

cat <<EOF >$R/$P-tools/setup.hint
sdesc: "The NetCDF library and commands for reading and writing NetCDF format (Tools)"
ldesc: "The NetCDF library and commands for reading and writing NetCDF format (Tools)"
category: Commandline_Utilities
requires: $P
external-source: $P
maintainer: $MAINTAINER
EOF

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "The NetCDF library and commands for reading and writing NetCDF format (Development)"
ldesc: "The NetCDF library and commands for reading and writing NetCDF format (Development)"
category: Libs
requires: $P
external-source: $P
maintainer: $MAINTAINER
EOF

cp ../$P-c-$V/COPYRIGHT $R/$P-$V-$B.txt
cp ../$P-c-$V/COPYRIGHT $R/$P-devel/$P-devel-$V-$B.txt
cp ../$P-c-$V/COPYRIGHT $R/$P-tools/$P-tools-$V-$B.txt

sed -e "s#$(cygpath -am install)#@osgeo4w_msys@#" install/bin/nc-config >install/bin/nc-config.tmpl

mkdir -p install/etc/postinstall install/etc/preremove

cat >install/etc/postinstall/$P.bat <<EOF
textreplace -std -t "%OSGEO4W_ROOT%\\bin\\nc-config"
EOF

cat >install/etc/preremove/$P.bat <<EOF
del "%OSGEO4W_ROOT%\\bin\\nc-config"
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	bin/nc-config.tmpl \
	bin/netcdf.dll

tar -C install -cjf $R/$P-tools/$P-tools-$V-$B.tar.bz2 \
	--exclude bin/nc-config \
	--exclude bin/nc-config.tmpl \
	--exclude "*.dll" \
	bin

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	include lib etc

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
