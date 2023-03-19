export P=pdal
export V=2.5.2
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="gdal-devel libgeotiff-devel libtiff-devel zlib-devel curl-devel libxml2-devel hdf5-devel openssl-devel zstd-devel laszip-devel"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V-src.tar.gz ] || wget https://github.com/PDAL/PDAL/releases/download/$V/${P^^}-$V-src.tar.gz
[ -f ../$P-$V/CMakeLists.txt ] || tar -C .. -xzf $P-$V-src.tar.gz --xform "s,^${P^^}-$V-src,$P-$V,"

(
	set -e

	vs2019env
	cmakeenv
	ninjaenv

	mkdir -p build install
	cd build

	export LIB="$(cygpath -aw ../osgeo4w/lib);$LIB"
	export INCLUDE="$(cygpath -aw ../osgeo4w/include);$INCLUDE"

	cmake -G Ninja \
		-D CMAKE_BUILD_TYPE=Release \
		-D CMAKE_INSTALL_PREFIX=../install \
		-D PDAL_PLUGIN_INSTALL_PATH=../install/apps/$P/plugins \
		../../$P-$V
	cmake --build .
	cmake --build . --target install || cmake --build . --target install

	sed -i -e "s#$(cygpath -am ../install)#\$OSGEO4W_ROOT_MSYS#g" -e "s#$(cygpath -am ../osgeo4w)#\$OSGEO4W_ROOT_MSYS#g" ../install/bin/pdal-config
	sed -i -e "s#$(cygpath -am ../install)#%OSGEO4W_ROOT%#g"      -e "s#$(cygpath -am ../osgeo4w)#%OSGEO4W_ROOT%#g" ../install/bin/pdal-config.bat
)

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-{devel,libs}

cat <<EOF >$R/setup.hint
sdesc: "PDAL: Point Data Abstraction Library (Executable)"
ldesc: "PDAL is a library for manipulating and translating point cloud data"
category: Commandline_Utilities
requires: $P-libs
category: Libs
requires: msvcrt2019
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	--exclude "bin/pdal-config*" \
	--exclude "bin/*.dll" \
	bin

cp ../$P-$V/LICENSE.txt $R/$P-$V-$B.txt

cat <<EOF >$R/$P-libs/setup.hint
sdesc: "PDAL: Point Data Abstraction Library (Runtime)"
ldesc: "PDAL is a library for manipulating and translating point cloud data"
category: Libs
requires: $RUNTIMEDEPENDS libgeotiff zlib curl libxml2 hdf5 openssl zstd laszip
maintainer: $MAINTAINER
external-source: $P
EOF

mkdir -p install/etc/ini

cat <<EOF >install/etc/ini/$P-libs.bat
set PDAL_DRIVER_PATH=%OSGEO4W_ROOT%\\apps\\$P\\plugins
EOF

tar -C install -cjf $R/$P-libs/$P-libs-$V-$B.tar.bz2 \
	--exclude "bin/pdal-config*" \
	--exclude "bin/pdal.exe" \
	etc/ini/$P-libs.bat \
	bin

cp ../$P-$V/LICENSE.txt $R/$P-libs/$P-libs-$V-$B.txt

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "PDAL: Point Data Abstraction Library (Development)"
ldesc: "PDAL is a library for manipulating and translating point cloud data"
category: Libs
requires: $P-libs liblas-devel laszip-devel
maintainer: $MAINTAINER
external-source: $P
EOF

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	--exclude "bin/*.dll" \
	--exclude "bin/pdal.exe" \
	bin include lib

cp ../$P-$V/LICENSE.txt $R/$P-devel/$P-devel-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
