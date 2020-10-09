export P=proj
export V=7.1.1
export B=next
export MAINTAINER=JuergenFischer

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget https://download.osgeo.org/$P/$P-$V.tar.gz
[ -f ../CMakeLists.txt ] || tar -C .. -xzf  $P-$V.tar.gz --xform "s,^$P-$V,.,"

fetchdeps sqlite3-devel libtiff-devel curl-devel

vs2019env
cmakeenv
ninjaenv

mkdir -p build install
cd build

export INCLUDE="$INCLUDE;$(cygpath -aw osgeo4w/include)"
export LIB="$LIB;$(cygpath -aw osgeo4w/lib)"

cmake -G Ninja \
	-D CMAKE_BUILD_TYPE=Release \
	-D CMAKE_INSTALL_PREFIX=../install \
	-D PROJ_LIB_SUBDIR=lib \
	-D PROJ_CMAKE_SUBDIR=share/cmake/proj4 \
	-D PROJ_DATA_SUBDIR=share/proj \
	-D PROJ_INCLUDE_SUBDIR=include \
	-D SQLITE3_LIBRARY=$(cygpath -aw ../osgeo4w/lib/sqlite3_i.lib) \
	-D SQLITE3_INCLUDE_DIR=$(cygpath -aw ../osgeo4w/include) \
	-D TIFF_LIBRARY=$(cygpath -aw ../osgeo4w/lib/tiff.lib) \
	-D TIFF_INCLUDE_DIR=$(cygpath -aw ../osgeo4w/include) \
	-D CURL_LIBRARY=$(cygpath -aw ../osgeo4w/lib/libcurl.lib) \
	-D CURL_INCLUDE_DIR=$(cygpath -aw ../osgeo4w/include) \
	-D BUILD_TESTING=OFF \
	-D BUILD_SHARED_LIBS=ON \
	../..
ninja
ninja install

cd ..

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "The PROJ library and commands for coordinate system transformations (Runtime)."
ldesc: "The PROJ library and commands for coordinate system transformations (Runtime)."
category: Libs Commandline_Utilities
requires: msvcrt2019 sqlite3 libtiff curl proj-data
maintainer: $MAINTAINER
EOF

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "The PROJ library and commands for coordinate system transformations (Development)."
ldesc: "The PROJ library and commands for coordinate system transformations (Development)."
category: Libs Commandline_Utilities
requires: $P
maintainer: $MAINTAINER
external-source: $P
EOF

cp ../COPYING $R/$P-$V-$B.txt

cat <<EOF >install/bin/$P-env.bat
SET PROJ_LIB=%OSGEO4W_ROOT%\\share\\proj
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	--hard-dereference \
	bin

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	--hard-dereference \
	include \
	lib \
	share
		
tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
