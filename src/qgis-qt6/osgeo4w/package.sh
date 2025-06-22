export P=qgis-qt6
export V=tbd
export B=tbd
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="expat-devel fcgi-devel proj-devel qt6-qml qt6-oci sqlite3-devel geos-devel gsl-devel libiconv-devel libzip-devel libspatialindex-devel python3-pip python3-pyqt6 python3-sip python3-pyqt-builder python3-devel python3-pyqt6-qscintilla python3-nose2 python3-future python3-pyyaml python3-mock python3-six qca-qt6-devel qscintilla-qt6-devel qt6-devel qwt-qt6-devel libspatialite-devel oci-devel qtkeychain-qt6-devel zlib-devel opencl-devel exiv2-devel protobuf-devel python3-setuptools zstd-devel libpq-devel libxml2-devel hdf5-devel hdf5-tools netcdf-devel pdal pdal-devel grass draco-devel libtiff-devel python3-oauthlib gdal-devel"
export PACKAGES="qgis-qt6 qgis-qt6-common qgis-qt6-deps qgis-qt6-devel qgis-qt6-full qgis-qt6-full-free qgis-qt6-grass-plugin qgis-qt6-oracle-provider qgis-qt6-pdb qgis-qt6-server"

: ${REPO:=https://github.com/qgis/QGIS.git}
: ${SITE:=qgis.org}
: ${TARGET:=Release}
: ${CC:=cl.exe}
: ${CXX:=cl.exe}
: ${BUILDCONF:=Release}

export SITE TARGET CC CXX BUILDCONF

source ../../../scripts/build-helpers

startlog

# Get latest release branch
RELBRANCH=$(git ls-remote --heads $REPO "refs/heads/release-*_*" | sed -e '/\^{}$/d' -ne 's#^.*refs/heads/release-#release-#p' | sort -V | tail -1)
RELBRANCH=${RELBRANCH#*/}

RELTAG=$(git ls-remote --tags $REPO "refs/tags/final-${RELBRANCH#release-}_*" | sed -e '/\^{}$/d' -ne 's#^.*refs/tags/final-#final-#p' | sort -V | tail -1)

cd ..

if [ -d qgis ]; then
	cd qgis
	git config core.filemode false

	git fetch origin +refs/tags/$RELTAG:refs/tags/$RELTAG
	git clean -f
	git reset --hard

	git checkout -f $RELTAG
else
	git clone $REPO --branch $RELTAG --single-branch --depth 1 qgis
	cd qgis
fi

if [ -s ../osgeo4w/patch ]; then
	git apply --allow-empty --check ../osgeo4w/patch
	git apply --allow-empty ../osgeo4w/patch
fi

SHA=$(git log -n1 --pretty=%h)

MAJOR=$(sed -ne 's/SET(CPACK_PACKAGE_VERSION_MAJOR "\([0-9]*\)")/\1/ip' CMakeLists.txt)
MINOR=$(sed -ne 's/SET(CPACK_PACKAGE_VERSION_MINOR "\([0-9]*\)")/\1/ip' CMakeLists.txt)
PATCH=$(sed -ne 's/SET(CPACK_PACKAGE_VERSION_PATCH "\([0-9]*\)")/\1/ip' CMakeLists.txt)

availablepackageversions $P
# Version: $QGISVER-$BUILD-$SHA-$BINARY

V=$MAJOR.$MINOR.$PATCH

if [ -n "$version_curr" ]; then
	build=$binary_curr

	if [ "$V" = "$version_curr" ]; then
		(( ++build ))
	fi
else
	build=1
fi

nextbinary

(
	set -e
	set -x

	cd $OSGEO4W_PWD

	fetchenv osgeo4w/bin/o4w_env.bat
	fetchenv osgeo4w/bin/qt6_env.bat

	vsenv
	cmakeenv
	ninjaenv
	ccacheenv

	export BUILDNAME=$P-$V-$TARGET-VC17-x86_64
	export BUILDDIR=$PWD/build
	export INSTDIR=$PWD/install
	export SRCDIR=$(cygpath -am ../qgis)
	export O4W_ROOT=$(cygpath -am osgeo4w)
	export LIB_DIR=$(cygpath -aw osgeo4w)

	mkdir -p $BUILDDIR

	unset PYTHONPATH
	export INCLUDE="$(cygpath -aw $OSGEO4W_ROOT/apps/Qt6/include);$(cygpath -aw $OSGEO4W_ROOT/include);$INCLUDE"
	export LIB="$(cygpath -aw $OSGEO4W_ROOT/apps/Qt6/lib);$(cygpath -aw $OSGEO4W_ROOT/lib);$LIB"

	export GRASS=$(cygpath -aw $O4W_ROOT/bin/grass*.bat)
	export GRASS_VERSION=$(unset SHELL; cmd /c $GRASS --config version | sed -e "s/\r//")
	export GRASS_PREFIX=$(unset SHELL; cmd /c $GRASS --config path | sed -e "s/\r//")

	cd $BUILDDIR

	echo CMAKE: $(date)

	rm -f qgsversion.h
	touch $SRCDIR/CMakeLists.txt

	OSGEO4W_SKIP_TESTS=1

	cmake -G Ninja \
		-D CMAKE_CXX_COMPILER="$(cygpath -m $CXX)" \
		-D CMAKE_C_COMPILER="$(cygpath -m $CC)" \
		-D CMAKE_LINKER=link.exe \
		-D SUBMIT_URL="https://cdash.orfeo-toolbox.org/submit.php?project=QGIS" \
		-D CMAKE_CXX_FLAGS_${BUILDCONF^^}="/MD /Z7 /MP /O2 /Ob2 /D NDEBUG /std:c++17 /permissive-" \
		-D CMAKE_PDB_OUTPUT_DIRECTORY_${BUILDCONF^^}=$(cygpath -am $BUILDDIR/apps/$P/pdb) \
		-D CMAKE_SHARED_LINKER_FLAGS_${BUILDCONF^^}="/INCREMENTAL:NO /DEBUG /OPT:REF /OPT:ICF" \
		-D CMAKE_MODULE_LINKER_FLAGS_${BUILDCONF^^}="/INCREMENTAL:NO /DEBUG /OPT:REF /OPT:ICF" \
		-D BUILDNAME="$BUILDNAME" \
		-D SITE="$SITE" \
		-D PEDANTIC=TRUE \
		-D WITH_QSPATIALITE=TRUE \
		-D WITH_SERVER=TRUE \
		-D SERVER_SKIP_ECW=TRUE \
		-D BUILD_WITH_QT5=FALSE \
		-D BUILD_WITH_QT6=TRUE \
		-D WITH_QTWEBKIT=FALSE \
		-D USE_OPENCL=TRUE \
		-D WITH_3D=TRUE \
		-D WITH_PDAL=TRUE \
		-D WITH_HANA=TRUE \
		-D WITH_GRASS=TRUE \
		-D WITH_GRASS8=TRUE \
		-D GRASS_PREFIX8="$(cygpath -m $GRASS_PREFIX)" \
		-D WITH_ORACLE=TRUE \
		-D WITH_CUSTOM_WIDGETS=TRUE \
		-D CMAKE_BUILD_TYPE=$BUILDCONF \
		-D CMAKE_CONFIGURATION_TYPES="$BUILDCONF" \
		-D SETUPAPI_LIBRARY="$(cygpath -am "/cygdrive/c/Program Files (x86)/Windows Kits/10/Lib/$UCRTVersion/um/x64/SetupAPI.Lib")" \
		-D PROJ_INCLUDE_DIR=$(cygpath -am $O4W_ROOT/include) \
		-D POSTGRES_INCLUDE_DIR=$(cygpath -am $O4W_ROOT/include) \
		-D GEOS_LIBRARY=$(cygpath -am "$O4W_ROOT/lib/geos_c.lib") \
		-D SQLITE3_LIBRARY=$(cygpath -am "$O4W_ROOT/lib/sqlite3_i.lib") \
		-D SPATIALITE_LIBRARY=$(cygpath -am "$O4W_ROOT/lib/spatialite_i.lib") \
		-D SPATIALINDEX_LIBRARY=$(cygpath -am $O4W_ROOT/lib/spatialindex-64.lib) \
		-D Python_EXECUTABLE=$(cygpath -am $O4W_ROOT/bin/python3.exe) \
		-D SIP_MODULE_EXECUTABLE=$(cygpath -am $PYTHONHOME/Scripts/sip-module.exe) \
		-D PYUIC_PROGRAM=$(cygpath -am $PYTHONHOME/Scripts/pyuic6.exe) \
		-D PYRCC_PROGRAM=$(cygpath -am $PYTHONHOME/Scripts/pyrcc6.exe) \
		-D PYTHON_INCLUDE_PATH=$(cygpath -am $PYTHONHOME/include) \
		-D PYTHON_LIBRARY=$(cygpath -am $PYTHONHOME/libs/$(basename $PYTHONHOME).lib) \
		-D QT_LIBRARY_DIR=$(cygpath -am $O4W_ROOT/lib) \
		-D QT_HEADERS_DIR=$(cygpath -am $O4W_ROOT/apps/qt6/include) \
		-D CMAKE_INSTALL_PREFIX=$(cygpath -am $INSTDIR/apps/$P) \
		-D CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_NO_WARNINGS=TRUE \
		-D FCGI_INCLUDE_DIR=$(cygpath -am $O4W_ROOT/include) \
		-D FCGI_LIBRARY=$(cygpath -am $O4W_ROOT/lib/libfcgi.lib) \
		-D QCA_INCLUDE_DIR=$(cygpath -am $O4W_ROOT/apps/Qt6/include/QtCrypto) \
		-D QCA_LIBRARY=$(cygpath -am $O4W_ROOT/apps/Qt6/lib/qca-qt6.lib) \
		-D QWT_LIBRARY=$(cygpath -am $O4W_ROOT/apps/Qt6/lib/qwt.lib) \
		-D QSCINTILLA_LIBRARY=$(cygpath -am $O4W_ROOT/apps/Qt6/lib/qscintilla2.lib) \
		-D DART_TESTING_TIMEOUT=60 \
		-D PUSH_TO_CDASH=TRUE \
		$(cygpath -m $SRCDIR)

	if [ -z "$OSGEO4W_SKIP_CLEAN" ]; then
		echo CLEAN: $(date)
		cmake --build $(cygpath -am $BUILDDIR) --target clean --config $BUILDCONF
	fi

	mkdir -p $BUILDDIR/apps/$P/pdb

	echo ALL_BUILD: $(date)
	cmake --build $(cygpath -am $BUILDDIR) --config $BUILDCONF
	tag=$(head -1 $BUILDDIR/Testing/TAG | sed -e "s/\r//")
	if grep -q "<Error>" $BUILDDIR/Testing/$tag/Build.xml; then
		sed -e '/src\\/ s#\\#/#g' $BUILDDIR/Testing/Temporary/LastBuild_$tag.log
		if [ -z "$OSGEO4W_SKIP_CLEAN" ]; then
			cmake --build $(cygpath -am $BUILDDIR) --target ${TARGET}Submit --config $BUILDCONF || echo SUBMISSION FAILED
		fi
		exit 1
	fi

	if [ -z "$OSGEO4W_SKIP_TESTS" ]; then
	(
		cd $SRCDIR

		echo RUN_TESTS: $(date)
		reg add "HKCU\\Software\\Microsoft\\Windows\\Windows Error Reporting" /v DontShow /t REG_DWORD /d 1 /f

		export TEMP=$TEMP/$P
		export TMP=$TEMP
		export TMPDIR=$TEMP

		rm -rf "$TEMP"
		mkdir -p $TEMP

		export PATH="$PATH:$(cygpath -au $GRASS_PREFIX/lib)"
		export GISBASE=$(cygpath -aw $GRASS_PREFIX)

		export PATH=$(cygpath -au $BUILDDIR/output/bin):$(cygpath -au $BUILDDIR/output/plugins):$PATH
		export QT_PLUGIN_PATH="$(cygpath -aw $BUILDDIR/output/plugins);$(cygpath -aw $O4W_ROOT/apps/qt6/plugins)"

		rm -f ../testfailure
		if ! cmake --build $(cygpath -am $BUILDDIR) --target Experimental --config $BUILDCONF; then
			echo TESTS FAILED: $(date)
			touch ../testfailure
		fi
	)
	fi

	rm -rf $INSTDIR
	mkdir -p $INSTDIR

	echo INSTALL: $(date)
	cmake --build $(cygpath -am $BUILDDIR) --target install --config $BUILDCONF
	cmakefix $INSTDIR

	echo PACKAGE: $(date)

	cd ..

	mkdir -p $INSTDIR/{etc/{postinstall,preremove},bin,httpd.d}

	v=$MAJOR.$MINOR.$PATCH

	sed -e "s/@package@/$P/g" -e "s/@version@/$v/g"       qgis.reg.tmpl           >install/apps/$P/bin/qgis.reg.tmpl
	sed -e "s/@package@/$P/g" -e "s/@version@/$v/g"       postinstall-common.bat  >install/etc/postinstall/$P-common.bat
	sed -e "s/@package@/$P/g" -e "s/@version@/$v/g"       postinstall-server.bat  >install/etc/postinstall/$P-server.bat
	sed -e "s/@package@/$P/g" -e "s/@version@/$v/g"       postinstall-desktop.bat >install/etc/postinstall/$P.bat
	sed -e "s/@package@/$P/g" -e "s/@version@/$v/g"       preremove-desktop.bat   >install/etc/preremove/$P.bat
	sed -e "s/@package@/$P/g" -e "s/@version@/$v/g"       preremove-server.bat    >install/etc/preremove/$P-server.bat
	sed -e "s/@package@/$P/g" -e "s/@version@/$v/g"       python.bat              >install/bin/python-$P.bat
	sed -e "s/@package@/$P/g" -e "s/@version@/$v/g"       designer.bat            >install/bin/$P-designer.bat
	sed -e "s/@package@/$P/g" -e "s/@version@/$v/g"       httpd.conf.tmpl         >install/httpd.d/httpd_$P.conf.tmpl

	sed -e "s/@package@/$P/g" -e "s/@version@/$v/g" -e "s/@grassversion@/$GRASS_VERSION/g" -e "s/@grasspath@/$(basename $GRASS_PREFIX)/g" -e "s/@grassmajor@/${GRASS_VERSION%%.*}/" qgis.bat    >install/bin/$P.bat
	sed -e "s/@package@/$P/g" -e "s/@version@/$v/g" -e "s/@grassversion@/$GRASS_VERSION/g" -e "s/@grasspath@/$(basename $GRASS_PREFIX)/g" -e "s/@grassmajor@/${GRASS_VERSION%%.*}/" process.bat >install/bin/qgis_process-$P.bat

	sed -e "s/@package@/$P/g" -e "s/@version@/$v/g" -e "s/@grassversion@/$GRASS_VERSION/g"                                                postinstall-grass.bat >install/etc/postinstall/$P-grass-plugin.bat
	sed -e "s/@package@/$P/g" -e "s/@version@/$v/g" -e "s/@grassversion@/$GRASS_VERSION/g"                                                preremove-grass.bat   >install/etc/preremove/$P-grass-plugin.bat

	cp "/cygdrive/c/Program Files (x86)/Windows Kits/10/Debuggers/x64/"{dbghelp.dll,symsrv.dll} install/apps/$P

	mv install/apps/$P/bin/qgis.exe install/bin/$P-bin.exe
	cp qgis.vars                    install/bin/$P-bin.vars

	mkdir -p                                                                   install/apps/$P/qtplugins/{sqldrivers,designer}
	mv osgeo4w/apps/qt6/plugins/sqldrivers/{qsqlocispatial,qsqlspatialite}.dll install/apps/$P/qtplugins/sqldrivers
	mv osgeo4w/apps/qt6/plugins/designer/qgis_customwidgets.dll                install/apps/$P/qtplugins/designer

	mkdir -p                                                                                 install/apps/$P/python/PyQt6/uic/widget-plugins
	mv osgeo4w/apps/Python*/Lib/site-packages/PyQt6/uic/widget-plugins/qgis_customwidgets.py install/apps/$P/python/PyQt6/uic/widget-plugins

	export R=$OSGEO4W_REP/x86_64/release/qgis/$P
	mkdir -p $R/$P-{pdb,full-free,full,deps,common,server,grass-plugin,oracle-provider,devel}

	touch exclude

	cat <<EOF >$R/$P-common/setup.hint
sdesc: "QGIS (common; Qt6)"
ldesc: "QGIS (common; Qt6)"
maintainer: $MAINTAINER
category: Libs
requires: msvcrt2019 $RUNTIMEDEPENDS libpq geos zstd gsl gdal libspatialite zlib libiconv libspatialindex qt6-libs qt6-qml qt6-tools qca-qt6 qwt-qt6-libs python3-sip python3-core python3-pyqt6 python3-psycopg2 python3-pyqt6-qscintilla python3-jinja2 python3-markupsafe python3-pygments python3-python-dateutil python3-pytz python3-nose2 python3-mock python3-httplib2 python3-future python3-pyyaml python3-gdal python3-requests python3-plotly python3-pyproj python3-owslib qtkeychain-qt6-libs libzip opencl exiv2 hdf5 pdal pdal-libs
external-source: $P
EOF

	cp ../qgis/COPYING $P-common-$V-$B.txt
	/bin/tar -C install -cjf $R/$P-common/$P-common-$V-$B.tar.bz2 \
		--exclude-from exclude \
		--exclude "*.pyc" \
		--exclude apps/$P/python/qgis/_server.pyd \
		--exclude apps/$P/python/qgis/_server.pyi \
		--exclude apps/$P/python/qgis/_server.lib \
		--exclude apps/$P/python/qgis/server \
		--exclude apps/$P/server/ \
	        apps/$P/python/ \
		apps/$P/bin/qgispython.dll \
		apps/$P/bin/qgis_analysis.dll \
		apps/$P/bin/qgis_3d.dll \
		apps/$P/bin/qgis_core.dll \
		apps/$P/bin/qgis_gui.dll \
		apps/$P/bin/qgis_native.dll \
		apps/$P/bin/qgis_process.exe \
		apps/$P/doc/ \
		apps/$P/plugins/authmethod_awss3.dll \
		apps/$P/plugins/authmethod_basic.dll \
		apps/$P/plugins/authmethod_esritoken.dll \
		apps/$P/plugins/authmethod_identcert.dll \
		apps/$P/plugins/authmethod_oauth2.dll \
		apps/$P/plugins/authmethod_pkcs12.dll \
		apps/$P/plugins/authmethod_pkipaths.dll \
		apps/$P/plugins/authmethod_apiheader.dll \
		apps/$P/plugins/authmethod_maptilerhmacsha256.dll \
		apps/$P/plugins/provider_arcgisfeatureserver.dll \
		apps/$P/plugins/provider_arcgismapserver.dll \
		apps/$P/plugins/provider_delimitedtext.dll \
		apps/$P/plugins/provider_gpx.dll \
		apps/$P/plugins/provider_hana.dll \
		apps/$P/plugins/provider_mdal.dll \
		apps/$P/plugins/provider_mssql.dll \
		apps/$P/plugins/provider_pdal.dll \
		apps/$P/plugins/provider_postgres.dll \
		apps/$P/plugins/provider_postgresraster.dll \
		apps/$P/plugins/provider_spatialite.dll \
		apps/$P/plugins/provider_virtuallayer.dll \
		apps/$P/plugins/provider_virtualraster.dll \
		apps/$P/plugins/provider_wcs.dll \
		apps/$P/plugins/provider_wfs.dll \
		apps/$P/plugins/provider_wms.dll \
		apps/$P/resources/qgis.db \
		apps/$P/resources/spatialite.db \
		apps/$P/resources/srs.db \
		apps/$P/resources/symbology-style.xml \
		apps/$P/resources/cpt-city-qgis-min/ \
		apps/$P/svg/ \
		apps/$P/crssync.exe \
		apps/$P/untwine.exe \
		apps/$P/pdal_wrench.exe \
		bin/qgis_process-$P.bat \
		etc/postinstall/$P-common.bat

	cat <<EOF >$R/$P-server/setup.hint
sdesc: "QGIS Server (Qt6)"
ldesc: "QGIS Server (Qt6)"
maintainer: $MAINTAINER
category: Web
requires: $P-common fcgi
external-source: $P
EOF

	cp ../qgis/COPYING $P-server-$V-$B.txt
	/bin/tar -C install -cjf $R/$P-server/$P-server-$V-$B.tar.bz2 \
		--exclude-from exclude \
		--exclude "*.pyc" \
	        apps/$P/bin/qgis_mapserv.fcgi.exe \
	        apps/$P/bin/qgis_server.dll \
	        apps/$P/resources/server/ \
	        apps/$P/server/ \
	        apps/$P/python/qgis/_server.pyd \
	        apps/$P/python/qgis/_server.pyi \
	        apps/$P/python/qgis/server/ \
	        httpd.d/httpd_$P.conf.tmpl \
	        etc/postinstall/$P-server.bat \
		etc/preremove/$P-server.bat

	cat <<EOF >$R/setup.hint
sdesc: "QGIS Desktop (Qt6)"
ldesc: "QGIS Desktop (Qt6)"
maintainer: $MAINTAINER
category: Desktop
requires: $P-common
EOF

	cp ../qgis/COPYING $R/$P-$V-$B.txt
	/bin/tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
		--exclude-from exclude \
	        apps/$P/i18n/ \
	        apps/$P/icons/ \
	        apps/$P/images/ \
	        apps/$P/plugins/plugin_offlineediting.dll \
	        apps/$P/plugins/plugin_topology.dll \
	        apps/$P/plugins/plugin_geometrychecker.dll \
	        apps/$P/qtplugins/sqldrivers/qsqlspatialite.dll \
	        apps/$P/qtplugins/designer/ \
	        apps/$P/resources/customization.xml \
	        apps/$P/resources/themes/ \
	        apps/$P/resources/data/ \
	        apps/$P/resources/metadata-ISO/ \
	        apps/$P/resources/opencl_programs/ \
	        apps/$P/resources/palettes/ \
	        apps/$P/resources/2to3migration.txt \
	        apps/$P/resources/qgis_global_settings.ini \
	        apps/$P/qgiscrashhandler.exe \
	        apps/$P/dbghelp.dll \
	        apps/$P/symsrv.dll \
	        apps/$P/bin/qgis.reg.tmpl \
	        bin/$P-bin.exe \
	        bin/$P-bin.vars \
	        bin/python-$P.bat \
	        bin/$P.bat \
	        bin/$P-designer.bat \
	        apps/$P/bin/qgis_app.dll \
	        etc/postinstall/$P.bat \
		etc/preremove/$P.bat

	cat <<EOF >$R/$P-pdb/setup.hint
sdesc: "Debugging symbols for QGIS (Qt6)"
ldesc: "Debugging symbols for QGIS (Qt6)"
maintainer: $MAINTAINER
category: Desktop
requires: $P
external-source: $P
EOF

	cp ../qgis/COPYING $R/$P-pdb/$P-pdb-$V-$B.txt
	/bin/tar -C build -cjf $R/$P-pdb/$P-pdb-$V-$B.tar.bz2 \
		apps/$P/pdb

	cat <<EOF >$R/$P-grass-plugin/setup.hint
sdesc: "GRASS plugin for QGIS (Qt6)"
ldesc: "GRASS plugin for QGIS (Qt6)"
maintainer: $MAINTAINER
category: Libs
requires: $P grass
external-source: $P
EOF

	cp ../qgis/COPYING $R/$P-grass-plugin/$P-grass-plugin-$V-$B.txt
	/bin/tar -C install -cjf $R/$P-grass-plugin/$P-grass-plugin-$V-$B.tar.bz2 \
		--exclude-from exclude \
		--exclude "*.pyc" \
		apps/$P/bin/qgisgrass8.dll \
		apps/$P/grass \
		apps/$P/plugins/plugin_grass8.dll \
		apps/$P/plugins/provider_grass8.dll \
		apps/$P/plugins/provider_grassraster8.dll \
		etc/postinstall/$P-grass-plugin.bat \
		etc/preremove/$P-grass-plugin.bat

	cat <<EOF >$R/$P-oracle-provider/setup.hint
sdesc: "Oracle provider plugin for QGIS (Qt6)"
ldesc: "Oracle provider plugin for QGIS (Qt6)"
maintainer: $MAINTAINER
category: Libs
requires: $P oci
external-source: $P
EOF

	cp ../qgis/COPYING $R/$P-oracle-provider/$P-oracle-provider-$V-$B.txt
	/bin/tar -C install -cjf $R/$P-oracle-provider/$P-oracle-provider-$V-$B.tar.bz2 \
		apps/$P/plugins/provider_oracle.dll \
		apps/$P/qtplugins/sqldrivers/qsqlocispatial.dll

	cat <<EOF >$R/$P-devel/setup.hint
sdesc: "QGIS development files (Qt6)"
ldesc: "QGIS development files (Qt6)"
maintainer: $MAINTAINER
category: Libs
requires: $P-common oci
external-source: $P
EOF

	cp ../qgis/COPYING $R/$P-devel/$P-devel-$V-$B.txt
	/bin/tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
		--exclude-from exclude \
		--exclude "*.pyc" \
		apps/$P/FindQGIS.cmake \
		apps/$P/include/ \
		apps/$P/lib/

	cat <<EOF >$R/$P-full-free/setup.hint
sdesc: "QGIS Desktop Full Free (meta package; Qt6)"
ldesc: "QGIS Desktop Full Free (meta package; Qt6)
without proprietary extensions"
maintainer: $MAINTAINER
category: Desktop
requires: $P proj $P-grass-plugin python3-pyparsing python3-simplejson python3-shapely python3-matplotlib python3-pygments python3-networkx python3-scipy python3-pyodbc python3-xlrd python3-xlwt setup python3-exifread python3-lxml python3-jinja2 python3-markupsafe python3-python-dateutil python3-pytz python3-nose2 python3-mock python3-httplib2 python3-pypiwin32 python3-future python3-pip python3-setuptools python3-pillow python3-geopandas python3-geographiclib python3-pyserial python3-pypdf2 python3-reportlab python3-openpyxl python3-remotior-sensus saga python3-psycopg python3-pyarrow qt6-tools gdal-sosi python3-pydantic
external-source: $P
EOF

	cat <<EOF >$R/$P-full/setup.hint
sdesc: "QGIS Desktop Full (meta package; Qt6)"
ldesc: "QGIS Desktop Full (meta package; Qt6)
including proprietary extensions"
maintainer: $MAINTAINER
category: Desktop
requires: $P-full-free $P-oracle-provider gdal-hdf5 gdal-mss gdal-ecw gdal-mrsid gdal-oracle
external-source: $P
EOF

	cat <<EOF >$R/$P-deps/setup.hint
sdesc: "QGIS build dependencies (meta package; Qt6)"
ldesc: "QGIS build dependencies (meta package; Qt6)"
maintainer: $MAINTAINER
category: Libs
requires: $BUILDDEPENDS
external-source: $P
EOF

	d=$(mktemp -d)
	cp ../qgis/COPYING $R/$P-full-free/$P-full-free-$V-$B.txt
	/bin/tar -C $d -cjf $R/$P-full-free/$P-full-free-$V-$B.tar.bz2 .
	cp ../qgis/COPYING $R/$P-full/$P-full-$V-$B.txt
	/bin/tar -C $d -cjf $R/$P-full/$P-full-$V-$B.tar.bz2 .
	cp ../qgis/COPYING $R/$P-deps/$P-deps-$V-$B.txt
	/bin/tar -C $d -cjf $R/$P-deps/$P-deps-$V-$B.tar.bz2 .
	rmdir $d

	appendversions $R/setup.hint
	appendversions $R/$P-deps/setup.hint
	appendversions $R/$P-pdb/setup.hint
	appendversions $R/$P-common/setup.hint
	appendversions $R/$P-server/setup.hint
	appendversions $R/$P-full-free/setup.hint
	appendversions $R/$P-full/setup.hint
	appendversions $R/$P-grass-plugin/setup.hint
	appendversions $R/$P-oracle-provider/setup.hint
	appendversions $R/$P-devel/setup.hint

	/bin/tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 \
		osgeo4w/package.sh \
		osgeo4w/process.bat \
		osgeo4w/designer.bat \
		osgeo4w/python.bat \
		osgeo4w/qgis.bat \
		osgeo4w/qgis.vars \
		osgeo4w/qgis.reg.tmpl \
		osgeo4w/patch \
		osgeo4w/httpd.conf.tmpl \
		osgeo4w/postinstall-common.bat \
		osgeo4w/postinstall-desktop.bat \
		osgeo4w/postinstall-grass.bat \
		osgeo4w/postinstall-server.bat \
		osgeo4w/preremove-desktop.bat \
		osgeo4w/preremove-grass.bat \
		osgeo4w/preremove-server.bat
)

endlog
