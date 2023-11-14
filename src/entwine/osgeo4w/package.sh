export P=entwine
export V=3.0.0
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="curl-devel openssl-devel pdal-devel python3-core"

source ../../../scripts/build-helpers

startlog

[ -f $V.tar.gz ] || wget -q https://github.com/connormanning/$P/archive/$V.tar.gz
[ -d ../$P-$V/CMakeLists.txt ] || tar -C .. -xzf $V.tar.gz

vs2019env
cmakeenv
ninjaenv

mkdir -p build install
cd build

export INCLUDE="$INCLUDE;$(cygpath -am ../osgeo4w/include)"
export LIB="$LIB;$(cygpath -am ../osgeo4w/lib)"

cmake -Wno-dev -G Ninja \
	-D CMAKE_BUILD_TYPE=Release \
	-D CMAKE_INSTALL_PREFIX=../install \
	-D CMAKE_PREFIX_PATH=$(cygpath -am ../osgeo4w/lib/cmake/PDAL) \
	-D BUILD_SHARED_LIBS=ON \
	-D PYTHON_EXECUTABLE=$(cygpath -am ../osgeo4w/bin/python3.exe) \
	-D CMAKE_CXX_FLAGS=/D_SILENCE_TR1_NAMESPACE_DEPRECATION_WARNING \
	-D WITH_TESTS=OFF \
	../../$P-$V
cmake --build .
cmake --build . --target install || cmake --build . --target install

cd ..

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "data organization library for massive point clouds (Runtime)"
ldesc: "Entwine is a data organization library for massive point clouds"
category: CommandLine_Utilities
requires: msvcrt2019 $RUNTIMEDEPENDS pdal-libs openssl curl
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 bin/entwine.exe

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "data organization library for massive point clouds (Development)"
ldesc: "Entwine is a data organization library for massive point clouds"
category: Libs
requires: $P
external-source: $P
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	include \
	lib

cp ../$P-$V/LICENSE $R/$P-$V-$B.txt
cp ../$P-$V/LICENSE $R/$P-devel/$P-devel-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
