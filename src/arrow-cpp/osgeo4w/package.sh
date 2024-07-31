export P=arrow-cpp
export V=17.0.0
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="boost-devel openssl-devel thrift-devel zstd-devel bzip2-devel zlib-devel lz4-devel brotli-devel snappy-devel protobuf-devel utf8proc python3-devel python3-pip python3-setuptools python3-wheel python3-numpy"
export PACKAGES="arrow-cpp arrow-cpp-devel python3-pyarrow"

source ../../../scripts/build-helpers

startlog

[ -f apache-arrow-$V.tar.gz ] || wget https://dist.apache.org/repos/dist/release/arrow/arrow-$V/apache-arrow-$V.tar.gz
sha256sum -c apache-arrow-$V.tar.gz.sha256
[ -d ../apache-arrow-$V ] || tar -C .. -xzf apache-arrow-$V.tar.gz
[ -f ../apache-arrow-$V/patched ] || {
	patch -d ../apache-arrow-$V -p1 --dry-run <diff
	patch -d ../apache-arrow-$V -p1 <diff >../apache-arrow-$V/patched
}

(
	fetchenv osgeo4w/bin/o4w_env.bat

	vsenv
	cmakeenv
	ninjaenv

	export LIB="$(cygpath -am osgeo4w/lib);$LIB"
	export INCLUDE="$(cygpath -am osgeo4w/include);$INCLUDE"
	export INCLUDE="$(cygpath -am osgeo4w/include/boost-1_84);$INCLUDE"

	mkdir -p build install
	cd build

	cmake -G Ninja \
		-D CMAKE_BUILD_TYPE=Release \
		-D CMAKE_INSTALL_PREFIX=../install \
		-D ARROW_DEPENDENCY_SOURCE=SYSTEM \
		-D ARROW_BOOST_USE_SHARED=OFF \
		-D Boost_USE_STATIC_LIBS=OFF \
		-D ARROW_BUILD_TESTS=OFF \
		-D ARROW_BUILD_STATIC=OFF \
		-D ARROW_COMPUTE=ON \
		-D ARROW_CSV=ON \
		-D ARROW_FILESYSTEM=ON \
		-D ARROW_HDFS=ON \
		-D ARROW_JSON=ON \
		-D ARROW_PARQUET=ON \
		-D ARROW_DATASET=ON \
		-D ARROW_WITH_RE2=OFF \
		-D ARROW_WITH_UTF8PROC=OFF \
		-D ARROW_WITH_SNAPPY=ON \
		-D ARROW_WITH_BROTLI=ON \
		-D ARROW_WITH_LZ4=ON \
		-D ARROW_WITH_ZLIB=ON \
			-D ZLIB_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
			-D ZLIB_LIBRARY_RELEASE=$(cygpath -am ../osgeo4w/lib/zlib.lib) \
		-D ARROW_WITH_ZSTD=ON \
			-D ZSTD_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
			-D ZSTD_LIB=$(cygpath -am ../osgeo4w/lib/zstd.lib) \
		-D ARROW_WITH_BZ2=ON \
			-D BZIP2_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
			-D BZIP2_LIBRARY_RELEASE=$(cygpath -am ../osgeo4w/lib/libbz2.lib) \
		-D ARROW_WITH_UTF8PROC=ON -D ARROW_UTF8PROC_USE_SHARED=OFF \
			-D utf8proc_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
			-D utf8proc_LIB=$(cygpath -am ../osgeo4w/lib/utf8proc_static.lib) \
		-D xsimd_SOURCE=BUNDLED \
		-D RapidJSON_SOURCE=BUNDLED \
		../../apache-arrow-$V/cpp

	cmake --build .
	cmake --build . --target install

	cmakefix ../install

	cd ../../apache-arrow-$V/python

	pip3 install Cython

	rm -rf build

	export INCLUDE="$(cygpath -am ../cpp/src);$INCLUDE"

	CMAKE_PREFIX_PATH="$CMAKE_PREFIX_PATH;$(cygpath -aw ../../osgeo4w/install/lib/cmake)" \
		PYARROW_CMAKE_GENERATOR=Ninja \
		PYARROW_BUILD_TYPE=Release \
		PYARROW_WITH_DATASET=ON \
		PYARROW_WITH_PARQUET=ON \
		python3 setup.py build_ext --inplace bdist_wheel

        wheel=$(cygpath -aw dist/*.whl) adddepends=$P externalsource=$P P=python3-pyarrow packagewheel --only-binary :all: --force-reinstall
)

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "Apache Arrow C++ library (runtime)"
ldesc: "Arrow C++ libraries, (runtime)"
category: Libs
requires: msvcrt2019 thrift brotli lz4 zlib zstd
maintainer: $MAINTAINER
EOF

cp ../apache-arrow-$V/LICENSE.txt $R/$P-$V-$B.txt
tar -C install -cjf $R/$P-$V-$B.tar.bz2 bin

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "Apache Arrow C++ library (development)"
ldesc: "Arrow C++ libraries, (development)"
category: Libs
requires: $P
maintainer: $MAINTAINER
external-source: $P
EOF

cp ../apache-arrow-$V/LICENSE.txt $R/$P-devel/$P-devel-$V-$B.txt
tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 include lib share

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh osgeo4w/diff

endlog
