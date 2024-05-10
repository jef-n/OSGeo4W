export P=gdal-dev
export V=tbd
export B=tbd
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-core swig zlib-devel proj-devel libpng-devel curl-devel geos-devel libmysql-devel sqlite3-devel netcdf-devel libpq-devel expat-devel xerces-c-devel szip-devel hdf4-devel hdf5-devel hdf5-tools ogdi-devel libiconv-devel openjpeg-devel libspatialite-devel freexl-devel libkml-devel xz-devel zstd-devel msodbcsql-devel poppler-devel libwebp-devel oci-devel openfyba-devel freetype-devel python3-devel python3-numpy libjpeg-turbo-devel python3-setuptools opencl-devel libtiff-devel arrow-cpp-devel lz4-devel openssl-devel lerc-devel kealib-devel odbc-cpp-wrapper-devel libjxl-devel libxml2-devel"
export PACKAGES="gdal-dev gdal-dev-devel gdal-dev-ecw gdal-dev-filegdb gdal-dev-hana gdal-dev-hdf5 gdal-dev-kea gdal-dev-mrsid gdal-dev-mss gdal-dev-oracle gdal-dev-sosi gdal-dev-tiledb gdal-dev305-runtime gdal-dev306-runtime gdal-dev307-runtime gdal-dev308-runtime gdal-dev309-runtime gdal-dev310-runtime python3-gdal-dev"

REPO=https://github.com/OSGeo/gdal.git

source ../../../scripts/build-helpers

startlog

if [ -d ../gdal ]; then
	cd ../gdal

	if [ -z "$OSGEO4W_SKIP_CLEAN" ]; then
		git clean -f
		git reset --hard

		git config pull.rebase false
		i=0
		until (( i > 10 )) || git pull; do
			(( ++i ))
		done
	fi

	cd ../osgeo4w
else
	git clone $REPO --branch master --single-branch ../gdal
	git config core.filemode false
	unset OSGEO4W_SKIP_CLEAN
fi

if [ -z "$OSGEO4W_SKIP_CLEAN" ]; then
	patch -p1 -d ../gdal --dry-run <patch
	patch -p1 -d ../gdal <patch
fi

SHA=$(cd ../gdal; git log -n1 --pretty=%h)

#
# Download MrSID, ECW and filegdb dependencies
#

mkdir -p gdaldeps
cd gdaldeps

export MRSID_SDK=MrSID_DSDK-9.5.5.5244-win64-vc17
export ECW_ZIP=ECWJP2SDKSetup_5.5.0.2268-Update4-Windows.zip
export ECW_EXE=ECWJP2SDKSetup_5.5.0.2268.exe

mkdir -p filegdb
[ -d filegdb/done ] || {
	[ -f FileGDB_API_VS2019.zip ] || wget -q https://github.com/Esri/file-geodatabase-api/raw/master/FileGDB_API_1.5.2/FileGDB_API_VS2019.zip
	sha256sum -c FileGDB_API_VS2019.zip.sha256sum
	unzip -q -o -d filegdb FileGDB_API_VS2019.zip "bin64/*" "lib64/*" "include/*" license/userestrictions.txt
	touch filegdb/done
}

mkdir -p ecw
[ -f ecw/done ] || {
	[ -f $ECW_ZIP ] || { echo ECW SDK download $ECW_ZIP missing; false; }
	sha256sum -c $ECW_ZIP.sha256sum
	[ -f $ECW_EXE ] || unzip -q $ECW_ZIP $ECW_EXE

	[ -x 7z.exe ] || {
		[ -f 7z2404-x64.exe ] || wget -q https://7-zip.org/a/7z2404-x64.exe
		sha256sum -c 7z2404-x64.exe.sha256sum
		7z x 7z2404-x64.exe 7z.exe 7z.dll
		chmod +x 7z.exe 7z.dll
	}

	./7z x -aoa -oecw $ECW_EXE \
		'$0/include/*' \
		lib/vc141/x64/NCSEcw.lib \
		lib/vc141/x64/NCSEcwS.lib \
		'bin/vc141/x64/*' \
		'$TEMP/ecwjp2_sdk/Server_Read-Only_EndUser.rtf' \
		ERDAS_ECW_JPEG2000_SDK.pdf

	mv 'ecw/$0/include' ecw/include
	rmdir 'ecw/$0'
	touch ecw/done
}

[ -f $MRSID_SDK/done ] || {
	[ -f "$MRSID_SDK.zip" ] || wget -q "https://bin.extensis.com/download/developer/$MRSID_SDK.zip"
	sha256sum -c $MRSID_SDK.zip.sha256sum

	unzip -o -q $MRSID_SDK.zip \
		"$MRSID_SDK/Raster_DSDK/include/*" \
		"$MRSID_SDK/Raster_DSDK/lib/*" \
		"$MRSID_SDK/Lidar_DSDK/include/*" \
		"$MRSID_SDK/Lidar_DSDK/lib/*" \
		"$MRSID_SDK/LICENSE.pdf"

	# 'add' VC2019 support
	cp "$MRSID_SDK/Raster_DSDK/include/lt_platform.h" "$MRSID_SDK/Raster_DSDK/include/lt_platform.h.orig"
	sed -i -e 's/#elif defined(_MSC_VER) &&  (1300 <= _MSC_VER && _MSC_VER <= 1910)/#elif defined(_MSC_VER) \&\& (1300 <= _MSC_VER \&\& _MSC_VER < 1930)/' \
		"$MRSID_SDK/Raster_DSDK/include/lt_platform.h"
	touch $MRSID_SDK/done
}

cd ..

availablepackageversions $P
# Version: $GDALVER-$BUILD-$SHA-$BINARY

V=$(<../gdal/VERSION)
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

R=$OSGEO4W_REP/x86_64/release/gdal/$P
mkdir -p $R/$P-{devel,oracle,filegdb,ecw,mrsid,sosi,mss,hdf5,kea,tiledb,hana} $R/$P$abi-runtime $R/python3-$P

if [ -f $R/$P-$V-$B-src.tar.bz2 ]; then
	echo "$R/$P-$V-$B-src.tar.bz2 already exists - skipping"
	exit 1
fi

export FGDB_SDK=$(cygpath -am gdaldeps/filegdb)
export ECW_SDK=$(cygpath -am gdaldeps/ecw)
export MRSID_SDK=$(cygpath -am gdaldeps/$MRSID_SDK)

(
	fetchenv osgeo4w/bin/o4w_env.bat

	vsenv
	cmakeenv
	ninjaenv

	export INCLUDE="$(cygpath -am osgeo4w/include);$(cygpath -am osgeo4w/apps/$PYTHON/include);$(cygpath -am osgeo4w/include/boost-1_84);$(cygpath -aw "$(find $VCINSTALLDIR -iname atlbase.h -printf '%h')");$INCLUDE"
	export LIB="$(cygpath -am osgeo4w/lib);$(cygpath -aw "$(find $VCINSTALLDIR -path "*/x64/*" -iname atls.lib -printf '%h')");$LIB"

	[ -n "$OSGEO4W_SKIP_CLEAN" ] || rm -rf build

	rm -rf install

	mkdir -p build
	cd build

	cmake --version

	cmake \
		-G Ninja \
		-D                      CMAKE_BUILD_TYPE=RelWithDebInfo \
		-D                  CMAKE_INSTALL_PREFIX=../install/apps/$P \
		-D                  GDAL_LIB_OUTPUT_NAME=$P$abi \
		-D                 BUILD_PYTHON_BINDINGS=ON \
		-D                   BUILD_JAVA_BINDINGS=OFF \
		-D                 BUILD_CSHARP_BINDINGS=OFF \
		-D                GDAL_USE_TIFF_INTERNAL=ON \
		-D             GDAL_USE_GEOTIFF_INTERNAL=ON \
		-D               GDAL_ENABLE_DRIVER_JPEG=ON \
		-D           GDAL_ENABLE_DRIVER_JP2MRSID=ON \
		-D                OGR_ENABLE_DRIVER_OGDI=ON \
		-D                   GDAL_USE_MSSQL_NCLI=OFF \
		-D                       GDAL_USE_OPENCL=ON \
		-D                     Python_EXECUTABLE=$(cygpath -am ../osgeo4w/apps/$PYTHON/python3.exe) \
		-D             Python_NumPy_INCLUDE_DIRS=$(cygpath -am ../osgeo4w/apps/$PYTHON/Lib/site-packages/numpy/core/include) \
		-D                       SWIG_EXECUTABLE=$(cygpath -am ../osgeo4w/bin/swig.bat) \
		-D                       ECW_INCLUDE_DIR=$(cygpath -am ../gdaldeps/ecw/include) \
		-D                           ECW_LIBRARY=$(cygpath -am ../gdaldeps/ecw/lib/vc141/x64/NCSEcw.lib) \
		-D                   FileGDB_INCLUDE_DIR=$(cygpath -am ../gdaldeps/filegdb/include) \
		-D                       FileGDB_LIBRARY=$(cygpath -am ../gdaldeps/filegdb/lib64/FileGDBAPI.lib) \
		-D                     MRSID_INCLUDE_DIR=$(cygpath -am $MRSID_SDK/Raster_DSDK/include) \
		-D                         MRSID_LIBRARY=$(cygpath -am $MRSID_SDK/Raster_DSDK/lib/lti_dsdk.lib) \
		-D                         MYSQL_LIBRARY=$(cygpath -am ../osgeo4w/lib/libmysql.lib) \
		-D                    MSSQL_ODBC_VERSION=18 \
		-D                    MSSQL_ODBC_LIBRARY=$(cygpath -am ../osgeo4w/lib/msodbcsql18.lib) \
		-D                  OPENJPEG_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include/openjpeg-2.5) \
		-D                           Oracle_ROOT=$(cygpath -am ../osgeo4w) \
		-D                        Oracle_LIBRARY=$(cygpath -am ../osgeo4w/lib/oci.lib) \
		-D                          JPEG_LIBRARY=$(cygpath -am ../osgeo4w/lib/jpeg.lib) \
		-D                       LZ4_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
		-D                   LZ4_LIBRARY_RELEASE=$(cygpath -am ../osgeo4w/lib/lz4.lib) \
		-D                   PNG_LIBRARY_RELEASE=$(cygpath -am ../osgeo4w/lib/libpng16.lib) \
		-D   _ICONV_SECOND_ARGUMENT_IS_NOT_CONST=1 \
		-D                         Iconv_LIBRARY=$(cygpath -am ../osgeo4w/lib/iconv.dll.lib) \
		-D                     FYBA_FYBA_LIBRARY=$(cygpath -am ../osgeo4w/lib/fyba.lib) \
		-D                     FYBA_FYGM_LIBRARY=$(cygpath -am ../osgeo4w/lib/gm.lib) \
		-D                     FYBA_FYUT_LIBRARY=$(cygpath -am ../osgeo4w/lib/ut.lib) \
		-D                     OGDI_INCLUDE_DIRS=$(cygpath -am ../osgeo4w/include/ogdi) \
		-D                          OGDI_LIBRARY=$(cygpath -am ../osgeo4w/lib/ogdi.lib) \
		-D                           KEA_LIBRARY=$(cygpath -am ../osgeo4w/lib/libkea.lib) \
		-D                              HDF5_DIR=$(cygpath -am ../osgeo4w/share/cmake) \
		-D                          LERC_LIBRARY=$(cygpath -am ../osgeo4w/lib/Lerc.lib) \
		-D                       SWIG_EXECUTABLE=$(cygpath -am ../osgeo4w/bin/swig.bat) \
		-D             GDAL_EXTRA_LINK_LIBRARIES="$(cygpath -am ../osgeo4w/lib/freetype.lib);$(cygpath -am ../osgeo4w/lib/jpeg.lib);$(cygpath -am ../osgeo4w/lib/tiff.lib);$(cygpath -am ../osgeo4w/lib/minizip.lib)" \
		-D OGR_ENABLE_DRIVER_PARQUET_PLUGIN=OFF \
		-D OGR_ENABLE_DRIVER_HANA_PLUGIN=ON -D OGR_DRIVER_HANA_PLUGIN_INSTALLATION_MESSAGE="You may enable it by installing the $P-hana package." \
		-D OGR_ENABLE_DRIVER_OCI_PLUGIN=ON -D OGR_DRIVER_OCI_PLUGIN_INSTALLATION_MESSAGE="You may enable it by installing the $P-oracle package." \
		-D OGR_ENABLE_DRIVER_FILEGDB_PLUGIN=ON -D OGR_DRIVER_FILEGDB_PLUGIN_INSTALLATION_MESSAGE="You may enable it by installing the $P-filegdb package." \
		-D OGR_ENABLE_DRIVER_SOSI_PLUGIN=ON -D OGR_DRIVER_SOSI_PLUGIN_INSTALLATION_MESSAGE="You may enable it by installing the $P-sosi package." \
		-D OGR_ENABLE_DRIVER_MSSQLSPATIAL_PLUGIN=ON -D OGR_DRIVER_MSSQLSPATIAL_PLUGIN_INSTALLATION_MESSAGE="You may enable it by installing the $P-mss package." \
		-D GDAL_ENABLE_DRIVER_GEOR_PLUGIN=ON -D GDAL_DRIVER_GEOR_PLUGIN_INSTALLATION_MESSAGE="You may enable it by installing the $P-oracle package." \
		-D GDAL_ENABLE_DRIVER_ECW_PLUGIN=ON -D GDAL_DRIVER_ECW_PLUGIN_INSTALLATION_MESSAGE="You may enable it by installing the $P-ecw package." \
		-D GDAL_ENABLE_DRIVER_MRSID_PLUGIN=ON -D GDAL_DRIVER_MRSID_PLUGIN_INSTALLATION_MESSAGE="You may enable it by installing the $P-mrsid package." \
		-D GDAL_ENABLE_DRIVER_HDF5_PLUGIN=ON -D GDAL_DRIVER_HDF5_PLUGIN_INSTALLATION_MESSAGE="You may enable it by installing the $P-hdf5 package." \
		-D GDAL_ENABLE_DRIVER_KEA_PLUGIN=ON -D GDAL_DRIVER_KEA_PLUGIN_INSTALLATION_MESSAGE="You may enable it by installing the $P-kea package." \
		../../gdal

	cmake --build . || cmake --build .
	cmake --build . --target install || cmake --build . --target install
	cmakefix ../install
)

mkdir -p install/etc/{postinstall,preremove}
>install/etc/postinstall/python3-$P.bat
>install/etc/preremove/python3-$P.bat

expytmpl=
for i in install/apps/$P/Scripts/*.py; do
	b=$(basename "$i" .py)

	cat <<EOF >install/apps/$P/Scripts/$b.bat
@echo off
call "%OSGEO4W_ROOT%\\bin\\$P-py-env.bat"
python -u "%OSGEO4W_ROOT%\\apps\\$P\\Scripts\\$b.py" %*
EOF
	(
		echo "#! @osgeo4w@\\apps\\$PYTHON\\python3.exe"
		tail -n +2 install/apps/$P/Scripts/$b.py
	) >install/apps/$P/Scripts/$b.py.tmpl

	echo -e "textreplace -std -t apps\\$P\\Scripts\\\\$b.py\r" >>install/etc/postinstall/python3-$P.bat
	echo -e "del apps\\$P\\Scripts\\\\$b.py\r" >>install/etc/preremove/python3-$P.bat

	expytmpl="$expytmpl --exclude apps/$P/Scripts/$b.py"
done

echo $(basename "install/apps/$P/lib/site-packages/GDAL"*.egg) >install/apps/$P/lib/site-packages/python3-$P.pth

echo -e "python -B \"%PYTHONHOME%\\Scripts\\preremove-cached.py\" python3-$P\r" >>install/etc/preremove/python3-$P.bat

mkdir -p install/etc/abi
cat <<EOF >install/etc/abi/$P-devel
$P$abi-runtime
EOF

mkdir -p install/bin
cat <<EOF >install/bin/$P-env.bat
SET GDAL_DATA=%OSGEO4W_ROOT%\\apps\\$P\\share\\gdal
SET GDAL_DRIVER_PATH=%OSGEO4W_ROOT%\\apps\\$P\\lib\\gdalplugins
PATH %OSGEO4W_ROOT%\\apps\\$P\\bin;%PATH%
EOF

cat <<EOF >install/bin/$P-py-env.bat
call $P-env.bat
SET PYTHONPATH=%OSGEO4W_ROOT%\\apps\\$P\\lib\\site-packages;%PYTHONPATH%
PATH %OSGEO4W_ROOT%\\apps\\$P\\Scripts;%PATH%
EOF

extradesc=" (nightly build)"

cat <<EOF >$R/setup.hint
sdesc: "The GDAL/OGR library and commandline tools$extradesc"
ldesc: "The GDAL/OGR library and commandline tools$extradesc"
maintainer: $MAINTAINER
category: Libs Commandline_Utilities
requires: msvcrt2019 $P$abi-runtime
EOF

cat <<EOF >$R/$P$abi-runtime/setup.hint
sdesc: "The GDAL/OGR $major.$minor runtime library$extradesc"
ldesc: "The GDAL/OGR $major.$minor runtime library$extradesc"
maintainer: $MAINTAINER
category: Libs Commandline_Utilities
requires: msvcrt2019 libpng curl geos libmysql sqlite3 netcdf libpq expat xerces-c hdf4 ogdi libiconv openjpeg libspatialite freexl xz zstd lz4 poppler msodbcsql libjpeg-turbo arrow-cpp thrift brotli libjxl libxml2 $RUNTIMEDEPENDS
external-source: $P
EOF

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "The GDAL/OGR headers and libraries$extradesc"
ldesc: "The GDAL/OGR headers and libraries$extradesc"
maintainer: $MAINTAINER
category: Libs Commandline_Utilities
requires: $P
external-source: $P
EOF

cat <<EOF >$R/python3-$P/setup.hint
sdesc: "The GDAL/OGR Python3 Bindings and Scripts$extradesc"
ldesc: "The GDAL/OGR Python3 Bindings and Scripts$extradesc"
category: Libs
requires: $P$abi-runtime python3-core python3-numpy
maintainer: $MAINTAINER
external-source: $P
EOF

cat <<EOF >$R/$P-oracle/setup.hint
sdesc: "OGR OCI and GDAL GeoRaster Plugins for Oracle$extradesc"
ldesc: "OGR OCI and GDAL GeoRaster Plugins for Oracle$extradesc"
category: Libs
requires: $P$abi-runtime oci
maintainer: $MAINTAINER
external-source: $P
EOF

cat <<EOF >$R/$P-filegdb/setup.hint
sdesc: "OGR FileGDB Driver$extradesc"
ldesc: "OGR FileGDB Driver$extradesc"
category: Libs
maintainer: $MAINTAINER
requires: $P$abi-runtime
external-source: $P
EOF

cat <<EOF >$R/$P-ecw/setup.hint
sdesc: "ECW Raster Plugin for GDAL$extradesc"
ldesc: "ECW Raster Plugin for GDAL$extradesc"
category: Libs
requires: $P$abi-runtime
maintainer: $MAINTAINER
external-source: $P
EOF

cat <<EOF >$R/$P-mrsid/setup.hint
sdesc: "MrSID Raster Plugin for GDAL$extradesc"
ldesc: "MrSID Raster Plugin for GDAL$extradesc"
category: Libs
maintainer: $MAINTAINER
requires: $P$abi-runtime
external-source: $P
EOF

cat <<EOF >$R/$P-sosi/setup.hint
sdesc: "OGR SOSI Driver$extradesc"
ldesc: "The OGR SOSI Driver enables OGR to read data in Norwegian SOSI standard (.sos)$extradesc"
category: Libs
requires: $P$abi-runtime
maintainer: $MAINTAINER
external-source: $P
EOF

cat <<EOF >$R/$P-mss/setup.hint
sdesc: "OGR plugin with SQL Native Client support for MSSQL Bulk Copy$extradesc"
ldesc: "OGR plugin with SQL Native Client support for MSSQL Bulk Copy$extradesc"
category: Libs
requires: $P$abi-runtime
maintainer: $MAINTAINER
external-source: $P
EOF

cat <<EOF >$R/$P-hdf5/setup.hint
sdesc: "HDF5 Plugin for GDAL$extradesc"
ldesc: "HDF5 Plugin for GDAL$extradesc"
category: Libs
maintainer: $MAINTAINER
requires: $P$abi-runtime hdf5
external-source: $P
EOF

cat <<EOF >$R/$P-kea/setup.hint
sdesc: "KEA Plugin for GDAL$extradesc"
ldesc: "KEA Plugin for GDAL$extradesc"
category: Libs
maintainer: $MAINTAINER
requires: $P$abi-runtime kealib
external-source: $P
EOF

cat <<EOF >$R/$P-tiledb/setup.hint
sdesc: "TILEDB plugin for GDAL$extradesc (obsolete)"
ldesc: "TILEDB plugin for GDAL$extradesc (obsolete)"
category: _obsolete
requires:
maintainer: $MAINTAINER
external-source: $P
EOF

cat <<EOF >$R/$P-hana/setup.hint
sdesc: "HANA plugin for GDAL$extradesc"
ldesc: "HANA plugin for GDAL$extradesc"
category: Libs
requires: $P$abi-runtime odbc-cpp-wrapper
maintainer: $MAINTAINER
external-source: $P
EOF

appendversions $R/setup.hint
appendversions $R/$P$abi-runtime/setup.hint
appendversions $R/$P-devel/setup.hint
appendversions $R/python3-$P/setup.hint
appendversions $R/$P-oracle/setup.hint
appendversions $R/$P-filegdb/setup.hint
appendversions $R/$P-ecw/setup.hint
appendversions $R/$P-mrsid/setup.hint
appendversions $R/$P-sosi/setup.hint
appendversions $R/$P-mss/setup.hint
appendversions $R/$P-hdf5/setup.hint
appendversions $R/$P-kea/setup.hint
appendversions $R/$P-tiledb/setup.hint
appendversions $R/$P-hana/setup.hint

cp ../gdal/LICENSE.TXT $R/$P-$V-$B.txt
cp ../gdal/LICENSE.TXT $R/$P-oracle/$P-oracle-$V-$B.txt
cp ../gdal/LICENSE.TXT $R/$P$abi-runtime/$P$abi-runtime-$V-$B.txt
cp ../gdal/LICENSE.TXT $R/$P-devel/$P-devel-$V-$B.txt
cp ../gdal/LICENSE.TXT $R/$P-mss/$P-mss-$V-$B.txt
cp ../gdal/LICENSE.TXT $R/$P-sosi/$P-sosi-$V-$B.txt
cp ../gdal/LICENSE.TXT $R/$P-hdf5/$P-hdf5-$V-$B.txt
cp ../gdal/LICENSE.TXT $R/$P-kea/$P-kea-$V-$B.txt
cp ../gdal/LICENSE.TXT $R/$P-tiledb/$P-tiledb-$V-$B.txt
cp ../gdal/LICENSE.TXT $R/$P-hana/$P-hana-$V-$B.txt
cp ../gdal/LICENSE.TXT $R/python3-$P/python3-$P-$V-$B.txt
cp $FGDB_SDK/license/userestrictions.txt $R/$P-filegdb/$P-filegdb-$V-$B.txt
catdoc $ECW_SDK/\$TEMP/ecwjp2_sdk/Server_Read-Only_EndUser.rtf | sed -e "1,/^[^ ]/ { /^$/d }" >$R/$P-ecw/$P-ecw-$V-$B.txt
pdftotext -layout -enc ASCII7 $MRSID_SDK/LICENSE.pdf - >$R/$P-mrsid/$P-mrsid-$V-$B.txt


cp $FGDB_SDK/bin64/FileGDBAPI.dll install/apps/$P/bin
cp $ECW_SDK/bin/vc141/x64/NCSEcw.dll install/apps/$P/bin
cp $MRSID_SDK/Raster_DSDK/lib/lti_dsdk_cdll_9.5.dll install/apps/$P/bin
cp $MRSID_SDK/Raster_DSDK/lib/tbb.dll install/apps/$P/bin
cp $MRSID_SDK/Raster_DSDK/lib/lti_dsdk_9.5.dll install/apps/$P/bin
cp $MRSID_SDK/Lidar_DSDK/lib/lti_lidar_dsdk_1.1.dll install/apps/$P/bin

tar -C install -cjvf $R/python3-$P/python3-$P-$V-$B.tar.bz2 \
	--exclude="*.pyc" \
	--exclude="__pycache__" \
	$expytmpl \
	apps/$P/lib/site-packages \
	apps/$P/Scripts \
	etc/postinstall/python3-$P.bat \
	etc/preremove/python3-$P.bat \
	bin/$P-py-env.bat

tar -C install -cjvf $R/$P-filegdb/$P-filegdb-$V-$B.tar.bz2 \
	apps/$P/lib/gdalplugins/ogr_FileGDB.dll \
	apps/$P/bin/FileGDBAPI.dll

tar -C install -cjvf $R/$P-sosi/$P-sosi-$V-$B.tar.bz2 \
	apps/$P/lib/gdalplugins/ogr_SOSI.dll

tar -C install -cjvf $R/$P-oracle/$P-oracle-$V-$B.tar.bz2 \
	apps/$P/lib/gdalplugins/gdal_GEOR.dll \
	apps/$P/lib/gdalplugins/ogr_OCI.dll

tar -C install -cjvf $R/$P-mss/$P-mss-$V-$B.tar.bz2 \
	apps/$P/lib/gdalplugins/ogr_MSSQLSpatial.dll

tar -C install -cjvf $R/$P-ecw/$P-ecw-$V-$B.tar.bz2 \
	apps/$P/lib/gdalplugins/gdal_ECW_JP2ECW.dll \
	apps/$P/bin/NCSEcw.dll

tar -C install -cjvf $R/$P-hdf5/$P-hdf5-$V-$B.tar.bz2 \
	apps/$P/lib/gdalplugins/gdal_HDF5.dll

tar -C install -cjvf $R/$P-kea/$P-kea-$V-$B.tar.bz2 \
	apps/$P/lib/gdalplugins/gdal_KEA.dll

d=$(mktemp -d)
tar -C $d -cjvf $R/$P-tiledb/$P-tiledb-$V-$B.tar.bz2 .
rmdir $d

tar -C install -cjvf $R/$P-hana/$P-hana-$V-$B.tar.bz2 \
	apps/$P/lib/gdalplugins/ogr_HANA.dll

tar -C install -cjvf $R/$P-mrsid/$P-mrsid-$V-$B.tar.bz2 \
	apps/$P/lib/gdalplugins/gdal_MrSID.dll \
	apps/$P/bin/lti_dsdk_cdll_9.5.dll \
	apps/$P/bin/lti_dsdk_9.5.dll \
	apps/$P/bin/lti_lidar_dsdk_1.1.dll \
	apps/$P/bin/tbb.dll

tar -C install -cjvf $R/$P$abi-runtime/$P$abi-runtime-$V-$B.tar.bz2 \
	apps/$P/bin/$P$abi.dll

cp install/apps/$P/lib/$P$abi.lib install/apps/$P/lib/gdal_i.lib
cp install/apps/$P/lib/$P$abi.lib install/apps/$P/lib/gdal.lib

tar -C install -cjvf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	--exclude "*.dll" \
	--exclude "apps/$P/lib/gdalplugins/drivers.ini" \
	--exclude "apps/$P/lib/site-packages" \
	apps/$P/include \
	apps/$P/lib \
	etc/abi/$P-devel

tar -C install -cjvf $R/$P-$V-$B.tar.bz2 \
	--exclude="apps/$P/lib/gdalplugins/*.dll" \
	--exclude="apps/$P/lib/site-packages" \
	--exclude="apps/$P/lib/pkgconfig" \
	--exclude="apps/$P/lib/cmake" \
	--exclude="apps/$P/bin/*.dll" \
	--exclude="apps/$P/lib/*.lib" \
	--exclude etc/abi/$P-devel \
	apps/$P/lib/gdalplugins/drivers.ini \
	apps/$P/bin \
	apps/$P/share \
	bin/$P-env.bat

tar -C .. -cjvf $R/$P-$V-$B-src.tar.bz2 \
	osgeo4w/package.sh \
	osgeo4w/patch

find install -type f |
	sed -re "/\.pyc$/d;
s#^install/##;
/apps\/$P\/Scripts\/.*\.py$/ { s/$/.tmpl/; }
" >/tmp/$P.installed

(
	tar tjf $R/$P-$V-$B.tar.bz2 | tee /tmp/$P.files
	for i in -filegdb -sosi -oracle -mss -ecw -mrsid -hdf5 -kea -tiledb -hana -devel $abi-runtime; do
		tar tjf $R/$P$i/$P$i-$V-$B.tar.bz2 | tee /tmp/$P-$i.files
	done
	tar tjf $R/python3-$P/python3-$P-$V-$B.tar.bz2 | tee /tmp/python3-$P.files
) >/tmp/$P.packaged

sort /tmp/$P.packaged | uniq -d >/tmp/$P.dupes
if [ -s /tmp/$P.dupes ]; then
	echo Duplicate files:
	cat /tmp/$P.dupes
	false
fi

if fgrep -v -x -f /tmp/$P.packaged /tmp/$P.installed >/tmp/$P.unpackaged; then
	echo Unpackaged files:
	cat /tmp/$P.unpackaged
	false
fi

if fgrep -v -x -f /tmp/$P.installed /tmp/$P.packaged | grep -v "/$" >/tmp/$P.generated; then
	echo Generated files:
	cat /tmp/$P.generated
	false
fi

if [ -s /tmp/$P.dupes ] || [ -s /tmp/$P.unpacked ] || [ -s /tmp/$P.generated ]; then
	exit 1
fi

endlog
