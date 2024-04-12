export P=kealib
export V=1.5.3
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="base hdf5-devel hdf5-tools"
export PACKAGES="kealib kealib-devel"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget https://github.com/ubarsc/$P/releases/download/$P-$V/$P-$V.tar.gz
[ -d ../$P-$V ] || tar -C .. -xzf $P-$V.tar.gz

(
	fetchenv osgeo4w/bin/o4w_env.bat

	vsenv
	cmakeenv
	ninjaenv

	mkdir -p build install
	cd build

	export LIB="$(cygpath -am osgeo4w/lib);$LIB"
	export INCLUDE="$(cygpath -am osgeo4w/include);$INCLUDE"

	cmake -G Ninja \
		-D CMAKE_BUILD_TYPE=Release \
		-D CMAKE_INSTALL_PREFIX=../install \
		../../$P-$V

	cmake --build .
	cmake --build . --target install
	cmakefix ../install
)

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "An HDF5 Based Raster File Format (runtime)"
ldesc: "An HDF5 Based Raster File Format (runtime)"
category: Libs
requires: msvcrt2019 hdf5
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 bin/libkea.dll

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "An HDF5 Based Raster File Format (development)"
ldesc: "An HDF5 Based Raster File Format (development)"
category: Libs
requires: $P
maintainer: $MAINTAINER
external-source: $P
EOF

cp ../$P-$V/LICENSE.txt $R/$P-$V-$B.txt

sed -i \
	-e 's#.:/src/osgeo4w/src/[^/]*/osgeo4w/install#%OSGEO4W_ROOT%#g' \
	install/bin/kea-config.bat

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	bin/kea-config.bat \
	lib \
	include

cp ../$P-$V/LICENSE.txt $R/$P-devel/$P-devel-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
