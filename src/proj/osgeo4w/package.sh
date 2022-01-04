export P=proj
export V=8.2.1
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="sqlite3-devel libtiff-devel curl-devel"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget https://download.osgeo.org/$P/$P-$V.tar.gz
[ -f ../$P-${V%RC*}/CMakeLists.txt ] || tar -C .. -xzf $P-$V.tar.gz

vs2019env
cmakeenv
ninjaenv

mkdir -p build-$V install
cd build-$V

export INCLUDE="$INCLUDE;$(cygpath -aw osgeo4w/include)"
export LIB="$LIB;$(cygpath -aw osgeo4w/lib)"
export PATH="$PATH:$OSGEO4W_PWD/osgeo4w/bin"
type sqlite3

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
	../../$P-${V%RC*}
ninja
ninja install

cd ..

abi=${V%.*}
abi=${abi//./}

export R=$OSGEO4W_REP/x86_64/release/$P

mkdir -p $R/$P-devel $R/$P$abi-runtime

mkdir -p install/etc/abi
echo $P$abi-runtime >install/etc/abi/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "The PROJ library and commands for coordinate system transformations (Tools)."
ldesc: "The PROJ library and commands for coordinate system transformations (Tools)."
category: Libs Commandline_Utilities
requires: $P$abi-runtime
maintainer: $MAINTAINER
EOF

cat <<EOF >$R/$P$abi-runtime/setup.hint
sdesc: "The PROJ library and commands for coordinate system transformations (Runtime)."
ldesc: "The PROJ library and commands for coordinate system transformations (Runtime)."
category: Libs
requires: msvcrt2019 sqlite3 libtiff curl proj-data $P$abi-runtime
maintainer: $MAINTAINER
external-source: $P
EOF

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "The PROJ library and commands for coordinate system transformations (Development)."
ldesc: "The PROJ library and commands for coordinate system transformations (Development)."
category: Libs
requires: $P
maintainer: $MAINTAINER
external-source: $P
EOF

appendversions $R/setup.hint
appendversions $R/$P$abi-runtime/setup.hint
appendversions $R/$P-devel/setup.hint

cp ../$P-${V%RC*}/COPYING $R/$P-$V-$B.txt

mkdir -p install/etc/ini
cat <<EOF >install/etc/ini/$P.bat
SET PROJ_LIB=%OSGEO4W_ROOT%\\share\\proj
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	--exclude "*.dll" \
	share/man \
	bin

tar -C install -cjf $R/$P$abi-runtime/$P$abi-runtime-$V-$B.tar.bz2 \
	--exclude "*.exe" \
	bin \
	etc/ini \
	share/proj

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	etc/abi/$P-devel \
	include \
	lib \
	share/cmake
		
tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
