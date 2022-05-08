export P=gdal-dev
export V=tbd
export B=tbd
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-core swig zlib-devel proj-devel libpng-devel curl-devel geos-devel libmysql-devel sqlite3-devel netcdf-devel libpq-devel expat-devel xerces-c-devel szip-devel hdf4-devel hdf5-devel hdf5-tools ogdi-devel libiconv-devel openjpeg-devel libspatialite-devel freexl-devel libkml-devel xz-devel zstd-devel msodbcsql-devel poppler-devel libwebp-devel oci-devel openfyba-devel freetype-devel python3-devel python3-numpy libjpeg-devel libjpeg12-devel python3-setuptools opencl-devel libtiff-devel arrow-cpp-devel lz4-devel libgeotiff-devel openssl-devel tiledb-devel"

REPO=https://github.com/OSGeo/gdal.git

source ../../../scripts/build-helpers

export PYTHON=Python39

startlog

# should be fixed in the packages
find $(find osgeo4w -name cmake) -type f | \
	xargs sed -i \
		-e 's#.:/src/osgeo4w/src/[^/]*/osgeo4w/install/#\$ENV{OSGEO4W_ROOT}/#g' \
		-e 's#.:/src/osgeo4w/src/[^/]*/osgeo4w/osgeo4w/#\$ENV{OSGEO4W_ROOT}/#g' \
		-e 's#.:\\\\src\\\\osgeo4w\\\\src\\\\[^\\]*\\\\osgeo4w\\\\osgeo4w\\\\#\$ENV{OSGEO4W_ROOT}\\\\#g' \
		-e 's#.:\\\\src\\\\osgeo4w\\\\src\\\\[^\\]*\\\\osgeo4w\\\\install\\\\#\$ENV{OSGEO4W_ROOT}\\\\#g'

if [ -d ../gdal ]; then
	cd ../gdal

	if [ -z "$OSGEO4W_SKIP_CLEAN" ]; then
		git clean -f
		git reset --hard
		git pull
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

[ -f osgeo4w/apps/$PYTHON/Lib/site-packages/setuptools/command/patched ] || {
	patch -p0 --dry-run <easy_install.diff
	patch -p0 <easy_install.diff
	touch osgeo4w/apps/Python39/Lib/site-packages/setuptools/command/patched
}

#
# Download MrSID, ECW and filegdb dependencies
#

mkdir -p gdaldeps
cd gdaldeps

export MRSID_SDK=MrSID_DSDK-9.5.4.4703-win64-vc14
export ECW_ZIP=ECWJP2SDKSetup_5.5.0.1882-Update2-Windows.zip
export ECW_EXE=ECWJP2SDKSetup_5.5.0.1882.exe

for i in \
	https://raw.githubusercontent.com/Esri/file-geodatabase-api/master/FileGDB_API_1.5/FileGDB_API_1_5_VS2015.zip \
	https://downloads.hexagongeospatial.com/software/2020/ECW/$ECW_ZIP \
	http://bin.lizardtech.com/download/developer/$MRSID_SDK.zip \
	; do
	[ -f "${i##*/}" ] || wget -q "$i"
done

mkdir -p filegdb
[ -d filegdb/done ] || {
	unzip -q -o -d filegdb FileGDB_API_1_5_VS2015.zip "bin64/*" "lib64/*" "include/*" license/userestrictions.txt
	touch filegdb/done
}

mkdir -p ecw
[ -f $ECW_EXE ] || unzip -q $ECW_ZIP $ECW_EXE ERDAS_ECW_JPEG2000_SDK.pdf
[ -f ecw/done ] || {
	7z x -aoa -oecw $ECW_EXE \
		'$0/include/*' \
		'lib/vc141/x64/NCSEcw.lib' \
		'lib/vc141/x64/NCSEcwS.lib' \
		'bin/vc141/x64/*' \
		'\$TEMP/ecwjp2_sdk/Server_Read-Only_EndUser.rtf'
	mv 'ecw/$0/include' ecw/include
	rmdir 'ecw/$0'
	touch ecw/done
}
[ -f $MRSID_SDK/done ] || {
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
		(( build++ )) || true
	fi
fi

V=$V-$build-$SHA
nextbinary

export abi=$(printf "%d%02d" $major $minor)

R=$OSGEO4W_REP/x86_64/release/gdal/$P
mkdir -p $R/$P-{devel,oracle,filegdb,ecw,mrsid,sosi,mss,hdf5} $R/$P$abi-runtime $R/python3-$P

if [ -f $R/$P-$V-$B-src.tar.bz2 ]; then
	echo "$R/$P-$V-$B-src.tar.bz2 already exists - skipping"
	exit 1
fi

export EXT_NMAKE_OPT=$(cygpath -am $PWD/nmake.opt)
export FGDB_SDK=$(cygpath -am gdaldeps/filegdb)
export ECW_SDK=$(cygpath -am gdaldeps/ecw)
export MRSID_SDK=$(cygpath -am gdaldeps/$MRSID_SDK)

(
	fetchenv osgeo4w/bin/o4w_env.bat

	vs2019env
	cmakeenv
	ninjaenv

	export INCLUDE="$(cygpath -am osgeo4w/include);$(cygpath -am osgeo4w/apps/Python39/include);$(cygpath -am osgeo4w/include/boost-1_74);$INCLUDE"
	export LIB="$(cygpath -am osgeo4w/lib);$LIB"

	mkdir -p build
	cd build

	cmake \
		-G Ninja \
		-D                      CMAKE_BUILD_TYPE=RelWithDebInfo \
		-D                  CMAKE_INSTALL_PREFIX=../install/apps/$P \
		-D                  GDAL_LIB_OUTPUT_NAME=gdal$abi \
		-D                 BUILD_PYTHON_BINDINGS=ON \
		-D                GDAL_USE_JPEG_INTERNAL=OFF \
		-D             GDAL_USE_GEOTIFF_INTERNAL=OFF \
		-D               GDAL_ENABLE_DRIVER_JPEG=ON \
		-D           GDAL_ENABLE_DRIVER_JP2MRSID=ON \
		-D                OGR_ENABLE_DRIVER_OGDI=ON \
		-D                   GDAL_USE_MSSQL_NCLI=OFF \
		-D                       GDAL_USE_OPENCL=ON \
		-D      OGR_ENABLE_DRIVER_PARQUET_PLUGIN=OFF \
		-D          OGR_ENABLE_DRIVER_OCI_PLUGIN=ON \
		-D        GDAL_ENABLE_DRIVER_GEOR_PLUGIN=ON \
		-D         GDAL_ENABLE_DRIVER_ECW_PLUGIN=ON \
		-D       GDAL_ENABLE_DRIVER_MRSID_PLUGIN=ON \
		-D        GDAL_ENABLE_DRIVER_HDF5_PLUGIN=ON \
		-D      OGR_ENABLE_DRIVER_FILEGDB_PLUGIN=ON \
		-D         OGR_ENABLE_DRIVER_SOSI_PLUGIN=ON \
		-D OGR_ENABLE_DRIVER_MSSQLSPATIAL_PLUGIN=ON \
		-D             Python_NumPy_INCLUDE_DIRS=$(cygpath -am ../osgeo4w/apps/Python39/Lib/site-packages/numpy/core/include) \
		-D                       SWIG_EXECUTABLE=$(cygpath -am ../osgeo4w/bin/swig.bat) \
		-D                       ECW_INCLUDE_DIR=$(cygpath -am ../gdaldeps/ecw/include) \
		-D                           ECW_LIBRARY=$(cygpath -am ../gdaldeps/ecw/lib/vc141/x64/NCSEcw.lib) \
		-D                   FileGDB_INCLUDE_DIR=$(cygpath -am ../gdaldeps/filegdb/include) \
		-D                       FileGDB_LIBRARY=$(cygpath -am ../gdaldeps/filegdb/lib64/FileGDBAPI.lib) \
		-D                     MRSID_INCLUDE_DIR=$(cygpath -am $MRSID_SDK/Raster_DSDK/include) \
		-D                         MRSID_LIBRARY=$(cygpath -am $MRSID_SDK/Raster_DSDK/lib/lti_dsdk.lib) \
		-D                         MYSQL_LIBRARY=$(cygpath -am ../osgeo4w/lib/libmysql.lib) \
		-D                    MSSQL_ODBC_VERSION=17 \
		-D                    MSSQL_ODBC_LIBRARY=$(cygpath -am ../osgeo4w/lib/msodbcsql17.lib) \
		-D                  OPENJPEG_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include/openjpeg-2.4) \
		-D                           Oracle_ROOT=$(cygpath -am ../osgeo4w) \
		-D                        Oracle_LIBRARY=$(cygpath -am ../osgeo4w/lib/oci.lib) \
		-D                          JPEG_LIBRARY=$(cygpath -am ../osgeo4w/lib/jpeg_i.lib) \
		-D                       LZ4_INCLUDE_DIR=$(cygpath -am ../osgeo4w/include) \
		-D	             LZ4_LIBRARY_RELEASE=$(cygpath -am ../osgeo4w/lib/lz4.lib) \
		-D                   PNG_LIBRARY_RELEASE=$(cygpath -am ../osgeo4w/lib/libpng16.lib) \
		-D   _ICONV_SECOND_ARGUMENT_IS_NOT_CONST=1 \
		-D                         Iconv_LIBRARY=$(cygpath -am ../osgeo4w/lib/iconv.dll.lib) \
		-D                     FYBA_FYBA_LIBRARY=$(cygpath -am ../osgeo4w/lib/fyba.lib) \
		-D                     FYBA_FYGM_LIBRARY=$(cygpath -am ../osgeo4w/lib/gm.lib) \
		-D                     FYBA_FYUT_LIBRARY=$(cygpath -am ../osgeo4w/lib/ut.lib) \
		-D                     OGDI_INCLUDE_DIRS=$(cygpath -am ../osgeo4w/include/ogdi) \
		-D                          OGDI_LIBRARY=$(cygpath -am ../osgeo4w/lib/ogdi.lib) \
		-D                       SWIG_EXECUTABLE=$(cygpath -am ../osgeo4w/bin/swig.bat) \
		-D             GDAL_EXTRA_LINK_LIBRARIES="$(cygpath -am ../osgeo4w/lib/freetype.lib);$(cygpath -am ../osgeo4w/lib/jpeg_i.lib);$(cygpath -am ../osgeo4w/lib/tiff.lib);$(cygpath -am ../osgeo4w/lib/uriparser.lib);$(cygpath -am ../osgeo4w/lib/minizip.lib)" \
		../../gdal

	cmake --build .
	cmake --build . --target install
)

mkdir -p install/etc/{postinstall,preremove}
>install/etc/postinstall/python3-$P.bat
>install/etc/preremove/python3-$P.bat

expytmpl=
for i in install/apps/$P/Scripts/*.py; do
	b=$(basename "$i" .py)

	cat <<EOF >install/apps/$P/Scripts/$b.bat
@echo off
call "%OSGEO4W_ROOT%\\bin\\o4w_env.bat"
python "%OSGEO4W_ROOT%\\apps\\$P\\Scripts\\$b.py" %*
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
SET GDAL_DATA=%OSGEO4W_ROOT%\\share\\$P
SET GDAL_DRIVER_PATH=%OSGEO4W_ROOT%\\apps\\$P\\lib\\gdalplugins
PATH %OSGEO4W_ROOT%\\apps\\$P\\bin;%PATH%
EOF

cat <<EOF >install/bin/$P-py-env.bat
call $P-env.bat
SET PYTHONPATH=%OSGEO4W_ROOT%\\apps\\$P\\lib\\site-packages;%PYTHONPATH%
PATH %OSGEO4W_ROOT%\\apps\\$P\\Scripts;%PATH%
EOF

cat <<EOF >$R/setup.hint
sdesc: "The GDAL/OGR library and commandline tools (nightly build)"
ldesc: "The GDAL/OGR library and commandline tools (nightly build)"
maintainer: $MAINTAINER
category: Libs Commandline_Utilities
requires: msvcrt2019 $P$abi-runtime
EOF

cat <<EOF >$R/$P$abi-runtime/setup.hint
sdesc: "The GDAL/OGR $major.$minor runtime library (nightly build)"
ldesc: "The GDAL/OGR $major.$minor runtime library (nightly build)"
maintainer: $MAINTAINER
category: Libs Commandline_Utilities
requires: msvcrt2019 libpng curl geos libmysql sqlite3 netcdf libpq expat xerces-c hdf4 ogdi libiconv openjpeg libspatialite freexl xz zstd poppler msodbcsql libjpeg libjpeg12 arrow-cpp thrift brotli tiledb $RUNTIMEDEPENDS
external-source: $P
EOF

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "The GDAL/OGR headers and libraries (nightly build)"
ldesc: "The GDAL/OGR headers and libraries (nightly build)"
maintainer: $MAINTAINER
category: Libs Commandline_Utilities
requires: $P
external-source: $P
EOF

cat <<EOF >$R/python3-$P/setup.hint
sdesc: "The GDAL/OGR Python3 Bindings and Scripts (nightly build)"
ldesc: "The GDAL/OGR Python3 Bindings and Scripts (nightly build)"
category: Libs
requires: $P$abi-runtime python3-core python3-numpy
maintainer: $MAINTAINER
external-source: $P
EOF

cat <<EOF >$R/$P-oracle/setup.hint
sdesc: "OGR OCI and GDAL GeoRaster Plugins for Oracle (nightly build)"
ldesc: "OGR OCI and GDAL GeoRaster Plugins for Oracle (nightly build)"
category: Libs
requires: $P$abi-runtime oci
maintainer: $MAINTAINER
external-source: $P
EOF

cat <<EOF >$R/$P-filegdb/setup.hint
sdesc: "OGR FileGDB Driver (nightly build)"
ldesc: "OGR FileGDB Driver (nightly build)"
category: Libs
maintainer: $MAINTAINER
requires: $P$abi-runtime
external-source: $P
EOF

cat <<EOF >$R/$P-ecw/setup.hint
sdesc: "ECW Raster Plugin for GDAL (nightly build)"
ldesc: "ECW Raster Plugin for GDAL (nightly build)"
category: Libs
requires: $P$abi-runtime
maintainer: $MAINTAINER
external-source: $P
EOF

cat <<EOF >$R/$P-mrsid/setup.hint
sdesc: "MrSID Raster Plugin for GDAL (nightly build)"
ldesc: "MrSID Raster Plugin for GDAL (nightly build)"
category: Libs
maintainer: $MAINTAINER
requires: $P$abi-runtime
external-source: $P
EOF

cat <<EOF >$R/$P-sosi/setup.hint
sdesc: "OGR SOSI Driver (nightly build)"
ldesc: "The OGR SOSI Driver enables OGR to read data in Norwegian SOSI standard (.sos) (nightly build)"
category: Libs
requires: $P$abi-runtime
maintainer: $MAINTAINER
external-source: $P
EOF

cat <<EOF >$R/$P-mss/setup.hint
sdesc: "OGR plugin with SQL Native Client support for MSSQL Bulk Copy (nightly build)"
ldesc: "OGR plugin with SQL Native Client support for MSSQL Bulk Copy (nightly build)"
category: Libs
requires: $P$abi-runtime
maintainer: $MAINTAINER
external-source: $P
EOF

cat <<EOF >$R/$P-hdf5/setup.hint
sdesc: "HDF5 Plugin for GDAL (nightly build)"
ldesc: "HDF5 Plugin for GDAL (nightly build)"
category: Libs
maintainer: $MAINTAINER
requires: $P$abi-runtime hdf5
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

cp ../gdal/LICENSE.TXT $R/$P-$V-$B.txt
cp ../gdal/LICENSE.TXT $R/$P-oracle/$P-oracle-$V-$B.txt
cp ../gdal/LICENSE.TXT $R/$P$abi-runtime/$P$abi-runtime-$V-$B.txt
cp ../gdal/LICENSE.TXT $R/$P-devel/$P-devel-$V-$B.txt
cp ../gdal/LICENSE.TXT $R/$P-mss/$P-mss-$V-$B.txt
cp ../gdal/LICENSE.TXT $R/$P-sosi/$P-sosi-$V-$B.txt
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

tar -C install -cjvf $R/$P-mrsid/$P-mrsid-$V-$B.tar.bz2 \
	apps/$P/lib/gdalplugins/gdal_MrSID.dll \
	apps/$P/bin/lti_dsdk_cdll_9.5.dll \
	apps/$P/bin/lti_dsdk_9.5.dll \
	apps/$P/bin/lti_lidar_dsdk_1.1.dll \
	apps/$P/bin/tbb.dll

tar -C install -cjvf $R/$P$abi-runtime/$P$abi-runtime-$V-$B.tar.bz2 \
	apps/$P/bin/gdal$abi.dll

mv install/apps/$P/lib/gdal$abi.lib install/apps/$P/lib/gdal_i.lib

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
	osgeo4w/easy_install.diff \
	osgeo4w/patch

find install -type f | sed -e "s#^install/##" >/tmp/$P.installed

(
	tar tjf $R/$P-$V-$B.tar.bz2 | tee /tmp/$P.files
	for i in -filegdb -sosi -oracle -mss -ecw -mrsid -hdf5 -devel $abi-runtime; do
		tar tjf $R/$P$i/$P$i-$V-$B.tar.bz2 | tee /tmp/$P-$i.files
	done
	tar tjf $R/python3-$P/python3-$P-$V-$B.tar.bz2 | tee /tmp/python3-$P.files
) >/tmp/$P.packaged

sort /tmp/$P.packaged | uniq -d >/tmp/$P.dupes
if [ -s /tmp/$P.dupes ]; then
	echo Duplicate files:
	cat /tmp/$P.dupes
fi

if fgrep -v -x -f /tmp/$P.packaged /tmp/$P.installed >/tmp/$P.unpackaged; then
	echo Unpackaged files:
	cat /tmp/$P.unpackaged
fi

if fgrep -v -x -f /tmp/$P.installed /tmp/$P.packaged | grep -v "/$" >/tmp/$P.generated; then
	echo Generated files:
	cat /tmp/$P.generated
fi

if [ -s /tmp/$P.dupes ] || [ -s /tmp/$P.unpacked ] || [ -s /tmp/$P.generated ]; then
	exit 1
fi

endlog
