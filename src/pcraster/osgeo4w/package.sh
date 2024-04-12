export P=pcraster
export V=4.4.1
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="gdal gdal-devel python3-core python3-devel python3-numpy python3-pybind11 xerces-c-devel qt5-devel qt5-oci boost-devel"
export PACKAGES="pcraster"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.bz2 ] || wget https://pcraster.geo.uu.nl/$P/packages/src/$P-$V.tar.bz2
[ -d ../$P-$V ] || tar -C .. -xjf $P-$V.tar.bz2
[ -f ../$P-$V/patched ] || {
	patch -d ../$P-$V -p1 --dry-run <patch
	patch -d ../$P-$V -p1 <patch
	touch ../$P-$V/patched
}

(
	set -e

	fetchenv osgeo4w/bin/o4w_env.bat
	vsenv
	cmakeenv
	ninjaenv

	mkdir -p install build

	cd build

	export INCLUDE="$(cygpath -aw ../osgeo4w/apps/$PYTHON/Lib/site-packages/numpy/core/include);$INCLUDE"
	export LIB="$(cygpath -aw ../osgeo4w/apps/$PYTHON/Lib/site-packages/numpy/core/lib);$LIB"

	export INCLUDE="$(cygpath -aw ../osgeo4w/apps/$PYTHON/Lib/site-packages/pybind11/include);$INCLUDE"
	export LIB="$(cygpath -aw ../osgeo4w/apps/$PYTHON/Lib/site-packages/pybind11/lib);$LIB"

	export LIB="$(cygpath -aw ../osgeo4w/apps/$PYTHON/Libs);$LIB"

	export INCLUDE="$(cygpath -aw ../osgeo4w/include);$(cygpath -aw ../osgeo4w/include/boost-1_84);$INCLUDE"
	export LIB="$(cygpath -aw ../osgeo4w/lib);$LIB"

	export PATH="$(cygpath -a ../osgeo4w/bin):$(cygpath -a ../osgeo4w/apps/qt5/bin):$PATH"

	cmake -G Ninja \
		-Wno-dev \
		-D CMAKE_PREFIX_PATH=$(cygpath -am ../osgeo4w/apps/qt5/lib/cmake) \
		-D CMAKE_TOOLCHAIN_FILE=$(cygpath -am ../msvs2019.cmake) \
		-D Boost_USE_STATIC_LIBS=ON \
		-D Boost_USE_MULTITHREADED=ON \
		-D Boost_USE_STATIC_RUNTIME=OFF \
		-D Boost_INCLUDE_DIR="$(cygpath -am ../osgeo4w/include/boost-1_84)" \
		-D Boost_LIBRARY_DIR="$(cygpath -am ../osgeo4w/lib)" \
		-D CMAKE_CXX_STANDARD=17 \
		-D CMAKE_BUILD_TYPE=Release \
		-D CMAKE_INSTALL_PREFIX=../install \
		-D PCRASTER_PYTHON_INSTALL_DIR=$(cygpath -am ../install/apps/$PYTHON/Lib/site-packages) \
		-D XercesC_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
		-D XercesC_LIBRARY=$(cygpath -am ../osgeo4w/lib/xerces-c_3.lib) \
		-D Python3_EXECUTABLE=$(cygpath -am ../osgeo4w/bin/python.exe) \
		-D pybind11_DIR=$(cygpath -am ../osgeo4w/apps/$PYTHON/Lib/site-packages/pybind11/share/cmake/pybind11) \
		-D PYBIND11_SYSTEM_INCLUDE=$(cygpath -aw ../osgeo4w/apps/$PYTHON/Lib/site-packages/pybind11/include) \
		-D Python3_NumPy_INCLUDE_DIR=$(cygpath -am ../osgeo4w/apps/$PYTHON/Lib/site-packages/numpy/core/include) \
		-D Qt5_DIR=$(cygpath -am ../osgeo4w/apps/Qt5) \
		-D PCRASTER_BUILD_TEST=OFF \
		../../$P-$V

	cmake --build .
	cmake --install . || cmake --install .
	cmakefix ../install
)

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R $R

cat <<EOF >$R/setup.hint
sdesc: "pcraster (Runtime)"
ldesc: "pcraster (Runtime)"
category: Libs
requires: msvcrt2019 python3-core $RUNTIMEDEPENDS qt5-libs
Maintainer: $MAINTAINER
EOF

cp ../$P-$V/LICENSE $R/$P-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 \
	osgeo4w/package.sh \
	osgeo4w/msvs2019.cmake

tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	bin \
	apps

endlog
