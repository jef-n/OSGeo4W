export P=qgis
export V=tbd
export B=tbd
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="expat-devel fcgi-devel proj-devel gdal-devel grass qt5-oci qt5-oci-debug sqlite3-devel geos-devel gsl-devel libiconv-devel libzip-devel libspatialindex-devel python3-pyqt5 python3-sip python3-devel python3-qscintilla python3-nose2 python3-future python3-pyyaml python3-mock python3-six qca-devel qscintilla-devel qt5-devel qwt-devel libspatialite-devel oci-devel qtkeychain-devel zlib-devel opencl-devel exiv2-devel protobuf-devel pdal pdal-devel python3-setuptools zstd-devel oci-devel qtwebkit-devel libpq-devel libxml2-devel hdf5-devel hdf5-tools netcdf-devel"

: ${SITE:=qgis.org}
: ${TARGET:=Release}
: ${CC:=cl.exe}
: ${CXX:=cl.exe}
: ${BUILDCONF:=Release}

REPO=https://github.com/qgis/QGIS.git

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

	git fetch origin +refs/tags/$RELTAG:refs/tags/$RELTAG
	git clean -f
	git reset --hard

	git checkout $RELTAG
else
	git clone $REPO --branch $RELTAG --single-branch --depth 1 qgis
	cd qgis
fi

patch -p1 --dry-run <../osgeo4w/patch
patch -p1 <../osgeo4w/patch

SHA=$(git log -n1 --pretty=%h)

MAJOR=$(sed -ne 's/SET(CPACK_PACKAGE_VERSION_MAJOR "\([0-9]*\)")/\1/ip' CMakeLists.txt)
MINOR=$(sed -ne 's/SET(CPACK_PACKAGE_VERSION_MINOR "\([0-9]*\)")/\1/ip' CMakeLists.txt)
PATCH=$(sed -ne 's/SET(CPACK_PACKAGE_VERSION_PATCH "\([0-9]*\)")/\1/ip' CMakeLists.txt)

availablepackageversions $P
# Version: $QGISVER-$BUILD-$SHA-$BINARY

V=$MAJOR.$MINOR.$PATCH

build=1
if [ -n "$version_curr" ]; then
	v=$version_curr
	version=${v%%-*}
	v=${v#*-}

	build=${v%%-*}

	if [ "$V" = "$version" ]; then
		(( build++ )) || true
	fi
fi

nextbinary

(
	set -e
	set -x

	cd $OSGEO4W_PWD

	fetchenv osgeo4w/bin/o4w_env.bat

	vs2019env
	cmakeenv
	ninjaenv

	export BUILDNAME=$P-$V-$TARGET-VC16-x86_64
	export BUILDDIR=$PWD/build
	export INSTDIR=$PWD/install
	export SRCDIR=$(cygpath -am ../qgis)
	export O4W_ROOT=$(cygpath -am osgeo4w)
	export LIB_DIR=$(cygpath -aw osgeo4w)

	mkdir -p $BUILDDIR

	fetchenv msvc-env.bat

	[ -f "$GRASS7" ]
	[ -d "$GRASS_PREFIX" ]
	[ -d "$DBGHLP_PATH" ]

	export GRASS_VERSION=$(cmd /c $GRASS7 --config version | sed -e "s/\r//")

	cd $BUILDDIR

	echo CMAKE: $(date)

	rm -f qgsversion.h
	touch $SRCDIR/CMakeLists.txt

	cmake -G Ninja \
		-D CMAKE_CXX_COMPILER="$(cygpath -m $CXX)" \
		-D CMAKE_C_COMPILER="$(cygpath -m $CC)" \
		-D CMAKE_LINKER=link.exe \
		-D CMAKE_CXX_FLAGS_${BUILDCONF^^}="/MD /Z7 /MP /O2 /Ob2 /D NDEBUG" \
		-D CMAKE_PDB_OUTPUT_DIRECTORY_${BUILDCONF^^}=$(cygpath -am $BUILDDIR/apps/$P/pdb) \
		-D CMAKE_SHARED_LINKER_FLAGS_${BUILDCONF^^}="/INCREMENTAL:NO /DEBUG /OPT:REF /OPT:ICF" \
		-D BUILDNAME="$BUILDNAME" \
		-D SITE="$SITE" \
		-D PEDANTIC=TRUE \
		-D WITH_QSPATIALITE=TRUE \
		-D WITH_SERVER=TRUE \
		-D SERVER_SKIP_ECW=TRUE \
		-D WITH_GRASS=TRUE \
		-D WITH_3D=TRUE \
		-D WITH_GRASS7=TRUE \
		-D WITH_PDAL=TRUE \
		-D WITH_HANA=TRUE \
		-D GRASS_PREFIX7="$(cygpath -m $GRASS_PREFIX)" \
		-D WITH_ORACLE=TRUE \
		-D WITH_CUSTOM_WIDGETS=TRUE \
		-D CMAKE_BUILD_TYPE=$BUILDCONF \
		-D CMAKE_CONFIGURATION_TYPES="$BUILDCONF" \
		-D SETUPAPI_LIBRARY="$SETUPAPI_LIBRARY" \
		-D GEOS_LIBRARY=$(cygpath -am "$O4W_ROOT/lib/geos_c.lib") \
		-D SQLITE3_LIBRARY=$(cygpath -am "$O4W_ROOT/lib/sqlite3_i.lib") \
		-D SPATIALITE_LIBRARY=$(cygpath -am "$O4W_ROOT/lib/spatialite_i.lib") \
		-D SPATIALINDEX_LIBRARY=$(cygpath -am $O4W_ROOT/lib/spatialindex-64.lib) \
		-D PYTHON_EXECUTABLE=$(cygpath -am $O4W_ROOT/bin/python3.exe) \
		-D SIP_BINARY_PATH=$(cygpath -am $PYTHONHOME/sip.exe) \
		-D PYTHON_INCLUDE_PATH=$(cygpath -am $PYTHONHOME/include) \
		-D PYTHON_LIBRARY=$(cygpath -am $PYTHONHOME/libs/$(basename $PYTHONHOME).lib) \
		-D QT_LIBRARY_DIR=$(cygpath -am $O4W_ROOT/lib) \
		-D QT_HEADERS_DIR=$(cyppath -am $O4W_ROOT/apps/qt5/include) \
		-D CMAKE_INSTALL_PREFIX=$(cygpath -am $INSTDIR/apps/$P) \
		-D CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_NO_WARNINGS=TRUE \
		-D FCGI_INCLUDE_DIR=$(cygpath -am $O4W_ROOT%/include) \
		-D FCGI_LIBRARY=$(cygpath -am $O4W_ROOT/lib/libfcgi.lib) \
		-D QCA_INCLUDE_DIR=$(cygpath -am $O4W_ROOT/apps/Qt5/include/QtCrypto) \
		-D QCA_LIBRARY=$(cygpath -am $O4W_ROOT/apps/Qt5/lib/qca-qt5.lib) \
		-D QWT_LIBRARY=$(cygpath -am $O4W_ROOT/apps/Qt5/lib/qwt.lib) \
		-D QSCINTILLA_LIBRARY=$(cygpath -am $O4W_ROOT/apps/Qt5/lib/qscintilla2.lib) \
		-D DART_TESTING_TIMEOUT=60 \
		$(cygpath -m $SRCDIR)

	echo CLEAN: $(date)
	cmake --build $(cygpath -am $BUILDDIR) --target clean --config $BUILDCONF

	mkdir -p $BUILDDIR/apps/$P/pdb

	echo ALL_BUILD: $(date)
	cmake --build $(cygpath -am $BUILDDIR) --config $BUILDCONF
	tag=$(head -1 $BUILDDIR/Testing/TAG | sed -e "s/\r//")
	if grep -q "<Error>" $BUILDDIR/Testing/$tag/Build.xml; then
		cat $BUILDDIR/Testing/Temporary/LastBuild_$tag.log
		cmake --build $(cygpath -am $BUILDDIR) --target ${TARGET}Submit --config $BUILDCONF
		exit 1
	fi

	(
		echo RUN_TESTS: $(date)
		reg add "HKCU\\Software\\Microsoft\\Windows\\Windows Error Reporting" /v DontShow /t REG_DWORD /d 1 /f

		export TEMP=$TEMP/$P
		export TMP=$TEMP
		export TMPDIR=$TEMP

		rm -rf "$TEMP"
		mkdir -p $TEMP

		export PATH="$PATH:$(cygpath -au $O4W_ROOT/apps/grass/$GRASS7_VERSION/lib)"
		export GISBASE=$(cygpath -aw $O4W_ROOT/apps/grass/$GRASS7_VERSION)

		export PATH=$PATH:$(cygpath -au $BUILDDIR/output/plugins)
		export QT_PLUGIN_PATH="$(cygpath -au $BUILDDIR/output/plugins);$(cygpath -au $O4W_ROOT/apps/qt5/plugins)"

		rm -f ../testfailure
		if ! cmake --build $(cygpath -am $BUILDDIR) --target Experimental --config $BUILDCONF; then
			echo TESTS FAILED: $(date)
			touch ../testfailure
		fi
	)

	rm -rf $INSTDIR
	mkdir -p $INSTDIR

	echo INSTALL: $(date)
	cmake --build $(cygpath -am $BUILDDIR) --target install --config $BUILDCONF

	echo PACKAGE: $(date)

	cd ..

	mkdir -p $INSTDIR/{etc/{postinstall,preremove},bin,httpd.d}

	v=$MAJOR.$MINOR.$PATCH

	sagadef=$(sed -rne "s/^REQUIRED_VERSION *= *('.*')$/\\1/p" install/apps/$P/python/plugins/processing/algs/saga/SagaAlgorithmProvider.py)
	sed -e "s/^REQUIRED_VERSION *= *'.*'$/REQUIRED_VERSION = @saga@/" install/apps/$P/python/plugins/processing/algs/saga/SagaAlgorithmProvider.py >install/apps/$P/python/plugins/processing/algs/saga/SagaAlgorithmProvider.py.tmpl

	sed -e "s/@package@/$P/g" -e "s/@version@/$v/g"       qgis.reg.tmpl           >install/apps/$P/bin/qgis.reg.tmpl
	sed -e "s/@package@/$P/g" -e "s/@version@/$v/g"       postinstall-common.bat  >install/etc/postinstall/$P-common.bat
	sed -e "s/@package@/$P/g" -e "s/@version@/$v/g"       postinstall-server.bat  >install/etc/postinstall/$P-server.bat
	sed -e "s/@package@/$P/g" -e "s/@version@/$v/g"       postinstall-desktop.bat >install/etc/postinstall/$P.bat
	sed -e "s/@package@/$P/g" -e "s/@version@/$v/g"       preremove-desktop.bat   >install/etc/preremove/$P.bat
	sed -e "s/@package@/$P/g" -e "s/@version@/$v/g"       preremove-server.bat    >install/etc/preremove/$P-server.bat
	sed -e "s/@package@/$P/g" -e "s/@version@/$v/g"       python.bat              >install/bin/python-$P.bat
	sed -e "s/@package@/$P/g" -e "s/@version@/$v/g"       process.bat             >install/bin/qgis_process-$P.bat
	sed -e "s/@package@/$P/g" -e "s/@version@/$v/g"       designer.bat            >install/bin/$P-designer.bat
	sed -e "s/@package@/$P/g" -e "s/@version@/$v/g"       httpd.conf.tmpl         >install/httpd.d/httpd_$P.conf.tmpl
	sed -e "s/@package@/$P/g" -e "s/@sagadef@/$sagadef/g" saga-refresh.bat        >install/apps/$P/saga-refresh.bat

	sed -e "s/@package@/$P/g" -e "s/@version@/$v/g" -e "s/@grassversion@/$GRASS_VERSION/g" -e "s/@grasspath@/$(basename $GRASS_PREFIX)/g" qgis.bat              >install/bin/$P.bat

	sed -e "s/@package@/$P/g" -e "s/@version@/$v/g" -e "s/@grassversion@/$GRASS_VERSION/g"                                                postinstall-grass.bat >install/etc/postinstall/$P-grass-plugin.bat
	sed -e "s/@package@/$P/g" -e "s/@version@/$v/g" -e "s/@grassversion@/$GRASS_VERSION/g"                                                preremove-grass.bat   >install/etc/preremove/$P-grass-plugin.bat

	cp "$DBGHLP_PATH"/{dbghelp.dll,symsrv.dll} install/apps/$P

	mv install/apps/$P/bin/qgis.exe install/bin/$P-bin.exe
	cp qgis.vars                    install/bin/$P-bin.vars

	mkdir -p                                                                   install/apps/$P/qtplugins/{sqldrivers,designer}
	mv osgeo4w/apps/qt5/plugins/sqldrivers/{qsqlocispatial,qsqlspatialite}.dll install/apps/$P/qtplugins/sqldrivers
	mv osgeo4w/apps/qt5/plugins/designer/qgis_customwidgets.dll                install/apps/$P/qtplugins/designer

	mkdir -p                                                                                 install/apps/$P/python/PyQt5/uic/widget-plugins
	mv osgeo4w/apps/Python*/Lib/site-packages/PyQt5/uic/widget-plugins/qgis_customwidgets.py install/apps/$P/python/PyQt5/uic/widget-plugins

	export R=$OSGEO4W_REP/x86_64/release/qgis/$P
	mkdir -p $R/$P-{pdb,full,deps,common,server,grass-plugin,oracle-provider,devel}

	touch exclude

	cat <<EOF >$R/$P-common/setup.hint
sdesc: "QGIS (common)"
ldesc: "QGIS (common)"
maintainer: $MAINTAINER
category: Libs
requires: msvcrt2019 $RUNTIMEDEPENDS libpq geos zstd gsl gdal libspatialite zlib libiconv libspatialindex qt5-libs qt5-qml qt5-tools qtwebkit-libs qca qwt-libs python3-sip python3-core python3-pyqt5 python3-psycopg2-binary python3-qscintilla python3-jinja2 python3-markupsafe python3-pygments python3-python-dateutil python3-pytz python3-nose2 python3-mock python3-httplib2 python3-future python3-pyyaml python3-gdal python3-requests python3-plotly python3-pyproj python3-owslib qtkeychain-libs libzip opencl exiv2 hdf5 pdal pdal-libs
external-source: $P
EOF

	/bin/tar -C install -cjf $R/$P-common/$P-common-$V-$B.tar.bz2 \
		--exclude-from exclude \
		--exclude "*.pyc" \
		--exclude apps/$P/python/qgis/_server.pyd \
		--exclude apps/$P/python/qgis/_server.lib \
		--exclude apps/$P/python/qgis/server \
		--exclude apps/$P/server/ \
		--exclude apps/$P/python/plugins/processing/algs/saga/SagaAlgorithmProvider.py \
	        apps/$P/python/ \
		apps/$P/bin/qgispython.dll \
		apps/$P/bin/qgis_analysis.dll \
		apps/$P/bin/qgis_3d.dll \
		apps/$P/bin/qgis_core.dll \
		apps/$P/bin/qgis_gui.dll \
		apps/$P/bin/qgis_native.dll \
		apps/$P/bin/qgis_process.exe \
		apps/$P/doc/ \
		apps/$P/plugins/basicauthmethod.dll \
		apps/$P/plugins/delimitedtextprovider.dll \
		apps/$P/plugins/esritokenauthmethod.dll \
		apps/$P/plugins/geonodeprovider.dll \
		apps/$P/plugins/gpxprovider.dll \
		apps/$P/plugins/identcertauthmethod.dll \
		apps/$P/plugins/mssqlprovider.dll \
		apps/$P/plugins/db2provider.dll \
		apps/$P/plugins/owsprovider.dll \
		apps/$P/plugins/pkcs12authmethod.dll \
		apps/$P/plugins/pkipathsauthmethod.dll \
		apps/$P/plugins/postgresprovider.dll \
		apps/$P/plugins/postgresrasterprovider.dll \
		apps/$P/plugins/spatialiteprovider.dll \
		apps/$P/plugins/virtuallayerprovider.dll \
		apps/$P/plugins/wcsprovider.dll \
		apps/$P/plugins/wfsprovider.dll \
		apps/$P/plugins/wmsprovider.dll \
		apps/$P/plugins/arcgismapserverprovider.dll \
		apps/$P/plugins/arcgisfeatureserverprovider.dll \
		apps/$P/plugins/mdalprovider.dll \
		apps/$P/plugins/hanaprovider.dll \
		apps/$P/plugins/pdalprovider.dll \
		apps/$P/plugins/oauth2authmethod.dll \
		apps/$P/resources/qgis.db \
		apps/$P/resources/spatialite.db \
		apps/$P/resources/srs.db \
		apps/$P/resources/symbology-style.xml \
		apps/$P/resources/cpt-city-qgis-min/ \
		apps/$P/svg/ \
		apps/$P/crssync.exe \
		apps/$P/untwine.exe \
		apps/$P/saga-refresh.bat \
		bin/qgis_process-$P.bat \
		etc/postinstall/$P-common.bat

	cat <<EOF >$R/$P-server/setup.hint
sdesc: "QGIS Server"
ldesc: "QGIS Server"
maintainer: $MAINTAINER
category: Web
requires: $P-common fcgi
external-source: $P
EOF

	/bin/tar -C install -cjf $R/$P-server/$P-server-$V-$B.tar.bz2 \
		--exclude-from exclude \
		--exclude "*.pyc" \
	        apps/$P/bin/qgis_mapserv.fcgi.exe \
	        apps/$P/bin/qgis_server.dll \
	        apps/$P/bin/admin.sld \
	        apps/$P/bin/wms_metadata.xml \
	        apps/$P/resources/server/ \
	        apps/$P/server/ \
	        apps/$P/python/qgis/_server.pyd \
	        apps/$P/python/qgis/server/ \
	        httpd.d/httpd_$P.conf.tmpl \
	        etc/postinstall/$P-server.bat \
		etc/preremove/$P-server.bat

	cat <<EOF >$R/setup.hint
sdesc: "QGIS Desktop"
ldesc: "QGIS Desktop"
maintainer: $MAINTAINER
category: Desktop
requires: $P-common
EOF

	/bin/tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
		--exclude-from exclude \
	        apps/$P/i18n/ \
	        apps/$P/icons/ \
	        apps/$P/images/ \
	        apps/$P/plugins/gpsimporterplugin.dll \
	        apps/$P/plugins/offlineeditingplugin.dll \
	        apps/$P/plugins/topolplugin.dll \
	        apps/$P/plugins/geometrycheckerplugin.dll \
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
sdesc: "Debugging symbols for QGIS"
ldesc: "Debugging symbols for QGIS"
maintainer: $MAINTAINER
category: Desktop
requires: $P
external-source: $P
EOF

	/bin/tar -C build -cjf $R/$P-pdb/$P-pdb-$V-$B.tar.bz2 \
		apps/$P/pdb

	cat <<EOF >$R/$P-grass-plugin/setup.hint
sdesc: "GRASS plugin for QGIS"
ldesc: "GRASS plugin for QGIS"
maintainer: $MAINTAINER
category: Libs
requires: $P grass
external-source: $P
EOF

	/bin/tar -C install -cjf $R/$P-grass-plugin/$P-grass-plugin-$V-$B.tar.bz2 \
		--exclude-from exclude \
		--exclude "*.pyc" \
		apps/$P/bin/qgisgrass7.dll \
		apps/$P/grass \
		apps/$P/plugins/grassplugin7.dll \
		apps/$P/plugins/grassprovider7.dll \
		apps/$P/plugins/grassrasterprovider7.dll \
		etc/postinstall/$P-grass-plugin.bat \
		etc/preremove/$P-grass-plugin.bat

	cat <<EOF >$R/$P-oracle-provider/setup.hint
sdesc: "Oracle provider plugin for QGIS"
ldesc: "Oracle provider plugin for QGIS"
maintainer: $MAINTAINER
category: Libs
requires: $P oci
external-source: $P
EOF

	/bin/tar -C install -cjf $R/$P-oracle-provider/$P-oracle-provider-$V-$B.tar.bz2 \
		apps/$P/plugins/oracleprovider.dll \
		apps/$P/qtplugins/sqldrivers/qsqlocispatial.dll

	cat <<EOF >$R/$P-devel/setup.hint
sdesc: "QGIS development files"
ldesc: "QGIS development files"
maintainer: $MAINTAINER
category: Libs
requires: $P-common oci
external-source: $P
EOF

	/bin/tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
		--exclude-from exclude \
		--exclude "*.pyc" \
		apps/$P/FindQGIS.cmake \
		apps/$P/include/ \
		apps/$P/lib/

	cat <<EOF >$R/$P-full/setup.hint
sdesc: "QGIS Full Desktop (meta package)"
ldesc: "QGIS Full Desktop (meta package)"
maintainer: $MAINTAINER
category: Desktop
requires: $P proj $P-grass-plugin $P-oracle-provider python3-pyparsing python3-simplejson python3-shapely python3-matplotlib gdal-hdf5 gdal-ecw gdal-mrsid gdal-oracle gdal-sosi python3-pygments qt5-tools python3-networkx python3-scipy python3-pyodbc python3-xlrd python3-xlwt setup python3-exifread python3-lxml python3-jinja2 python3-markupsafe python3-python-dateutil python3-pytz python3-nose2 python3-mock python3-httplib2 python3-pypiwin32 python3-future python3-pip python3-pillow python3-pandas python3-geographiclib saga
external-source: $P
EOF

	cat <<EOF >$R/$P-deps/setup.hint
sdesc: "QGIS build dependencies (meta package)"
ldesc: "QGIS build dependencies (meta package)"
maintainer: $MAINTAINER
category: Libs
requires: $BUILDDEPENDS
external-source: $P
EOF

	d=$(mktemp -d)
	/bin/tar -C $d -cjf $R/$P-full/$P-full-$V-$B.tar.bz2 .
	/bin/tar -C $d -cjf $R/$P-deps/$P-deps-$V-$B.tar.bz2 .
	rmdir $d

	appendversions $R/setup.hint
	appendversions $R/$P-pdb/setup.hint
	appendversions $R/$P-common/setup.hint
	appendversions $R/$P-server/setup.hint
	appendversions $R/$P-full/setup.hint
	appendversions $R/$P-deps/setup.hint
	appendversions $R/$P-grass-plugin/setup.hint
	appendversions $R/$P-oracle-provider/setup.hint
	appendversions $R/$P-devel/setup.hint

	/bin/tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 \
		osgeo4w/package.sh \
		osgeo4w/patch \
		osgeo4w/msvc-env.bat \
		osgeo4w/process.bat \
		osgeo4w/designer.bat \
		osgeo4w/python.bat \
		osgeo4w/qgis.bat \
		osgeo4w/qgis.vars \
		osgeo4w/httpd.conf.tmpl \
		osgeo4w/qgis.reg.tmpl \
		osgeo4w/postinstall-common.bat \
		osgeo4w/postinstall-desktop.bat \
		osgeo4w/postinstall-grass.bat \
		osgeo4w/postinstall-server.bat \
		osgeo4w/preremove-desktop.bat \
		osgeo4w/preremove-grass.bat \
		osgeo4w/preremove-server.bat
)

endlog
