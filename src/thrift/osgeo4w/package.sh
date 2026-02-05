export P=thrift
export V=0.21.0
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="boost-devel openssl-devel zlib-devel node"
export PACKAGES="thrift thrift-devel thrift-node"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget -c "https://dlcdn.apache.org/$P/$V/$P-$V.tar.gz"
[ -d ../$P-$V ] || tar -C .. -xzf $P-$V.tar.gz

cd ../osgeo4w

(
	fetchenv osgeo4w/bin/o4w_env.bat

	vsenv
	cmakeenv
	ninjaenv

	mkdir -p build install

	export LIB="$(cygpath -am osgeo4w/lib);$LIB"
	export INCLUDE="$(cygpath -am osgeo4w/include);$INCLUDE"

	cd build

	cmake -G Ninja \
		-D CMAKE_BUILD_TYPE=Release \
		-D CMAKE_INSTALL_PREFIX=../install \
		-D BUILD_TESTING=OFF \
		-D WITH_QT5=OFF \
		-D PKGCONFIG_INSTALL_DIR=$(cygpath -am ../install/share/pkgconfig) \
		-D CMAKE_INSTALL_DIR=$(cygpath -am ../install/cmake) \
		-D NODEJS_INSTALL_DIR=$(cygpath -am ../install/apps/node/node_modules/npm/node_modules) \
		-D LIB_INSTALL_DIR=$(cygpath -am ../install/lib) \
		../../$P-$V
	cmake --build .
	cmake --install .
	cmakefix ../install

	sed -i -e 's#$ENV{OSGEO4W_ROOT}/\$ENV{OSGEO4W_ROOT}#$ENV{OSGEO4W_ROOT}#' ../install/cmake/thrift/ThriftConfig.cmake
)

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-{devel,node}

cat <<EOF >$R/setup.hint
sdesc: "Apache thrift library (runtime)"
ldesc: "performant communication and data serialization across languages"
category: Libs
requires: msvcrt2019 openssl zlib
maintainer: $MAINTAINER
EOF

cp ../$P-$V/LICENSE $R/$P-$V-$B.txt
tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	bin/thriftmd.dll \
	bin/thriftzmd.dll

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "Apache thrift library (development)"
ldesc: "performant communication and data serialization across languages"
category: Libs
requires: msvcrt2019 $P boost-devel
maintainer: $MAINTAINER
external-source: $P
EOF

cp ../$P-$V/LICENSE $R/$P-devel/$P-devel-$V-$B.txt
tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	cmake \
	include \
	share \
	lib \
	bin/thrift.exe

cat <<EOF >$R/$P-node/setup.hint
sdesc: "Apache thrift library (nodejs)"
ldesc: "performant communication and data serialization across languages"
category: Libs
requires: msvcrt2019 $P node
maintainer: $MAINTAINER
external-source: $P
EOF

cp ../$P-$V/LICENSE $R/$P-node/$P-node-$V-$B.txt
tar -C install -cjf $R/$P-node/$P-node-$V-$B.tar.bz2 \
	apps/node

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
