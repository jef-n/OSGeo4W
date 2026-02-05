export P=pdal-dev
export V=tbd
export B=tbd
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="gdal-dev-devel libgeotiff-devel libtiff-devel zlib-devel curl-devel libxml2-devel hdf5-devel openssl-devel zstd-devel laszip-devel proj-devel draco-devel sqlite3-devel arrow-cpp-devel xz-devel"
export PACKAGES="pdal-dev pdal-dev-devel pdal-dev-libs"

REPO=https://github.com/PDAL/PDAL

source ../../../scripts/build-helpers

startlog

if [ -d ../pdal ]; then
	cd ../pdal

	if [ -z "$OSGEO4W_SKIP_CLEAN" ]; then
		git clean -f
		git reset --hard

		git config pull.rebase false
		i=0
		until (( i > 10 )) || git pull; do
			(( ++i ))
		done
		if (( i > 10 )); then
			echo pull failed
			exit 1
		fi
	fi
else
	git clone $REPO --branch master --single-branch ../pdal
	git config core.filemode false
	unset OSGEO4W_SKIP_CLEAN
	cd ../pdal
fi

if [ -z "$OSGEO4W_SKIP_CLEAN" ]; then
	git apply --allow-empty --check ../osgeo4w/patch
	git apply --allow-empty ../osgeo4w/patch
fi


SHA=$(git log -n1 --pretty=%h)

cd ../osgeo4w

availablepackageversions $P
# Version: $PDALVER-$BUILD-$SHA-$BINARY

V=$(sed -ne 's/project(PDAL VERSION \(.*\) LANGUAGES .*$/\1/p' ../pdal/CMakeLists.txt)
major=${V%%.*}
minor=${V#$major.}
minor=${minor%%.*}

build=1
if [[ "$version_curr" =~ ^[^-]*-[^-]*-[^-]*$ ]]; then
	v=$version_curr
	version=${v%%-*}
	v=${v#*-}

	build=${v%%-*}
	v=${v#*-}
	sha=${v%%-*}

	if [ "$SHA" = "$sha" -a -z "$OSGEO4W_FORCE_REBUILD" ]; then
		echo "$SHA already built."
		endlog
		exit 0
	fi

	if [ "$V" = "$version" ]; then
		(( ++build ))
	fi
fi

V=$V-$build-$SHA
nextbinary

export abi=$(printf "%d%02d" $major $minor)

(
	set -e

	vsenv
	cmakeenv
	ninjaenv

	[ -n "$OSGEO4W_SKIP_CLEAN" ] || rm -rf build install

	mkdir -p build install
	cd build

	export LIB="$(cygpath -aw ../osgeo4w/lib);$LIB"
	export INCLUDE="$(cygpath -aw ../osgeo4w/include);$INCLUDE"

	cmake -G Ninja \
		-D CMAKE_BUILD_TYPE=Release \
		-D CMAKE_INSTALL_PREFIX=../install/apps/$P \
		-D CMAKE_PREFIX_PATH=$(cygpath -m ../osgeo4w/apps/gdal-dev/lib/cmake/gdal) \
		-D PDAL_PLUGIN_INSTALL_PATH=../install/apps/$P/plugins \
		-D PDALCPP_LIB_OUTPUT_NAME=${P}cpp$abi \
		-D WITH_LZMA=ON \
		-D BUILD_PLUGIN_ARROW=ON \
		-D BUILD_PLUGIN_DRACO=ON \
		-D BUILD_PLUGIN_HDF=ON \
		-D SQLite3_LIBRARY=$(cygpath -am ../osgeo4w/lib/sqlite3_i.lib) \
		../../pdal
	cmake --build .
	cmake --build . --target install || cmake --build . --target install
	cmakefix ../install

	sed -i -e "s#$(cygpath -am ../install)#\$OSGEO4W_ROOT_MSYS#g" -e "s#$(cygpath -am ../osgeo4w)#\$OSGEO4W_ROOT_MSYS#g" ../install/apps/$P/bin/pdal-config
	sed -i -e "s#$(cygpath -am ../install)#%OSGEO4W_ROOT%#g"      -e "s#$(cygpath -am ../osgeo4w)#%OSGEO4W_ROOT%#g" ../install/apps/$P/bin/pdal-config.bat
)

export R=$OSGEO4W_REP/x86_64/release/pdal/$P
mkdir -p $R/$P-{devel,libs}

mkdir -p install/bin
cat <<EOF >install/bin/$P-env.bat
call %OSGEO4W_ROOT%\\bin\\gdal-dev-env.bat
set PDAL_DRIVER_PATH=%OSGEO4W_ROOT%\\apps\\$P\\plugins
PATH %OSGEO4W_ROOT%\\apps\\$P\\bin;%PATH%
EOF

extradesc=" (nightly build)"

cat <<EOF >$R/setup.hint
sdesc: "PDAL: Point Data Abstraction Library (Executable; $extradesc)"
ldesc: "PDAL is a library for manipulating and translating point cloud data"
category: Commandline_Utilities
requires: msvcrt2019 $P-libs
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	--exclude "apps/$P/bin/pdal-config*" \
	--exclude "apps/$P/bin/*.dll" \
	apps/$P/bin

cp ../pdal/LICENSE.txt $R/$P-$V-$B.txt

cat <<EOF >$R/$P-libs/setup.hint
sdesc: "PDAL: Point Data Abstraction Library (Runtime; $extradesc)"
ldesc: "PDAL is a library for manipulating and translating point cloud data"
category: Libs
requires: $RUNTIMEDEPENDS libgeotiff zlib curl libxml2 hdf5 openssl zstd laszip sqlite3 arrow-cpp
maintainer: $MAINTAINER
external-source: $P
EOF

tar -C install -cjf $R/$P-libs/$P-libs-$V-$B.tar.bz2 \
	--exclude "apps/$P/bin/pdal-config*" \
	--exclude "apps/$P/bin/pdal.exe" \
	apps/$P/bin \
	bin/$P-env.bat

cp ../pdal/LICENSE.txt $R/$P-libs/$P-libs-$V-$B.txt

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "PDAL: Point Data Abstraction Library (Development; $extradesc)"
ldesc: "PDAL is a library for manipulating and translating point cloud data"
category: Libs
requires: $P-libs liblas-devel laszip-devel
maintainer: $MAINTAINER
external-source: $P
EOF

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	--exclude "apps/$P/bin/*.dll" \
	--exclude "apps/$P/bin/pdal.exe" \
	apps/$P/bin \
	apps/$P/include \
	apps/$P/lib

cp ../pdal/LICENSE.txt $R/$P-devel/$P-devel-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh osgeo4w/patch

endlog
