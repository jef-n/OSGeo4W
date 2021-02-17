export P=qgis-dev
export V=tbd
export B=tbd
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="expat-devel fcgi-devel proj-devel gdal-devel grass qt5-oci qt5-oci-debug sqlite3-devel geos-devel gsl-devel libiconv-devel libzip-devel libspatialindex-devel python3-pyqt5 python3-sip python3-devel python3-qscintilla python3-nose2 python3-future python3-pyyaml python3-mock python3-six qca-devel qscintilla-devel qt5-devel qwt-devel libspatialite-devel oci-devel qtkeychain-devel zlib-devel opencl-devel exiv2-devel protobuf-devel pdal pdal-devel python3-setuptools zstd-devel oci-devel qtwebkit-devel libpq-devel libxml2-devel hdf5-devel hdf5-tools netcdf-devel"

: ${SITE:=qgis.org}
: ${TARGET:=Nightly}
: ${CC:=cl.exe}
: ${CXX:=cl.exe}
: ${BUILDCONF:=RelWithDebInfo}

REPO=https://github.com/qgis/QGIS.git

export SITE TARGET CC CXX BUILDCONF

source ../../../scripts/build-helpers

startlog

if cd ../qgis; then
	git reset --hard
	git pull
else
	cd ..
	git clone --depth 120 $REPO qgis
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

V=$V-$build-$SHA
nextbinary

(
	set -e
	set -x

	cd $OSGEO4W_PWD

	fetchenv osgeo4w/bin/o4w_env.bat

	vs2019env
	cmakeenv
	ninjaenv

	pip install transifex-client

	cd ../qgis


	if [ -n "$TX_TOKEN" ] && ! PATH=/bin:$PATH bash -x scripts/pull_ts.sh; then
		echo "TSPULL FAILED $?"
		rm -rf i18n doc/TRANSLATORS
		git checkout i18n doc/TRANSLATORS
	fi

	cd ../osgeo4w

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
		-D CMAKE_CXX_FLAGS_${BUILDCONF^^}="/MD /Z7 /MP /Od /D NDEBUG" \
		-D CMAKE_PDB_OUTPUT_DIRECTORY_${BUILDCONF^^}=$(cygpath -am $BUILDDIR/apps/$P/pdb) \
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
	cmake --build $(cygpath -am $BUILDDIR) --target ${TARGET}Build --config $BUILDCONF
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
		if ! cmake --build $(cygpath -am $BUILDDIR) --target ${TARGET}Test --config $BUILDCONF; then
			echo TESTS FAILED: $(date)
			touch ../testfailure
		fi
	)

	cmake --build $(cygpath -am $BUILDDIR) --target ${TARGET}Submit --config $BUILDCONF || echo SUBMISSION FAILED

	rm -rf $INSTDIR
	mkdir -p $INSTDIR

	echo INSTALL: $(date)
	cmake --build $(cygpath -am $BUILDDIR) --target install --config $BUILDCONF

	echo PACKAGE: $(date)

	cd ..

	mkdir -p $INSTDIR/{etc/{postinstall,preremove},bin}

	v=$MAJOR.$MINOR.$PATCH
	sed -e "s/@package@/$P/g" -e "s/@version@/$v/g"                                                                                       qgis.reg.tmpl   >install/bin/qgis.reg.tmpl
	sed -e "s/@package@/$P/g" -e "s/@version@/$v/g" -e "s/@grassversion@/$GRASS_VERSION/g"                                                postinstall.bat >install/etc/postinstall/$P.bat
	sed -e "s/@package@/$P/g" -e "s/@version@/$v/g" -e "s/@grassversion@/$GRASS_VERSION/g"                                                preremove.bat   >install/etc/preremove/$P.bat
	sed -e "s/@package@/$P/g" -e "s/@version@/$v/g" -e "s/@grassversion@/$GRASS_VERSION/g" -e "s/@grasspath@/$(basename $GRASS_PREFIX)/g" qgis-grass.bat  >install/bin/$P-grass.bat
	sed -e "s/@package@/$P/g" -e "s/@version@/$v/g"                                                                                       designer.bat    >install/bin/$P-designer.bat
	sed -e "s/@package@/$P/g" -e "s/@version@/$v/g"                                                                                       process.bat     >install/bin/qgis_process-$P.bat
	sed -e "s/@package@/$P/g" -e "s/@version@/$v/g" -e "/o4w_env.bat/a call gdal-dev-py3-env.bat"                                       qgis.bat        >install/bin/$P.bat
	sed -e "s/@package@/$P/g" -e "s/@version@/$v/g" -e "/o4w_env.bat/a call gdal-dev-py3-env.bat"                                       python.bat      >install/bin/python-$P.bat

	cp "$DBGHLP_PATH"/{dbghelp.dll,symsrv.dll} install/apps/$P

	mkdir -p install/apps/$P/python
	cp "$PYTHONHOME/Lib/site-packages/PyQt5/uic/widget-plugins/qgis_customwidgets.py" install/apps/$P/python

	export R=$OSGEO4W_REP/x86_64/release/qgis/$P
	mkdir -p $R/$P-{pdb,full}

	touch exclude
	/bin/tar -cjf $R/$P-$V-$B.tar.bz2 \
		--exclude-from exclude \
		--exclude "*.pyc" \
		--xform "s,^qgis.vars,bin/$P-bin.vars," \
		--xform "s,^osgeo4w/apps/qt5/plugins/,apps/$P/qtplugins/," \
		--xform "s,^install/apps/$P/bin/qgis.exe,bin/$P-bin.exe," \
		--xform "s,^install/,," \
		qgis.vars \
		osgeo4w/apps/qt5/plugins/sqldrivers/qsqlocispatial.dll \
		osgeo4w/apps/qt5/plugins/sqldrivers/qsqlspatialite.dll \
		osgeo4w/apps/qt5/plugins/designer/qgis_customwidgets.dll \
		install/

	/bin/tar -C $BUILDDIR -cjf $R/$P-pdb/$P-pdb-$V-$B.tar.bz2 \
		apps/$P/pdb

	d=$(mktemp -d)
	/bin/tar -C $d -cjf $R/$P-full/$P-full-$V-$B.tar.bz2 .
	rmdir $d

	cat <<EOF >$R/setup.hint
sdesc: "QGIS nightly build of the development branch"
ldesc: "QGIS nightly build of the development branch"
maintainer: $MAINTAINER
category: Desktop
requires: msvcrt2019 $RUNTIMEDEPENDS libpq geos zstd gsl gdal libspatialite zlib libiconv fcgi libspatialindex oci qt5-libs qt5-qml qt5-tools qtwebkit-libs qca qwt-libs python3-sip python3-core python3-pyqt5 python3-psycopg2-binary python3-qscintilla python3-jinja2 python3-markupsafe python3-pygments python3-python-dateutil python3-pytz python3-nose2 python3-mock python3-httplib2 python3-future python3-pyyaml python3-gdal python3-requests python3-plotly python3-pyproj python3-owslib qtkeychain-libs libzip opencl exiv2 hdf5 python3-gdal-dev pdal pdal-libs
EOF

	appendversions $R/setup.hint

	cat <<EOF >$R/$P-pdb/setup.hint
sdesc: "Debugging symbols for QGIS nightly build of the development branch"
ldesc: "Debugging symbols for QGIS nightly build of the development branch"
maintainer: $MAINTAINER
category: Desktop
requires: $P
external-source: $P
EOF

	appendversions $R/$P-pdb/setup.hint

	cat <<EOF >$R/$P-full/setup.hint
sdesc: "QGIS nightly build of the development branch (metapackage with additional dependencies)"
ldesc: "QGIS nightly build of the development branch (metapackage with additional dependencies)"
maintainer: $MAINTAINER
category: Desktop
requires: $P proj python3-pyparsing python3-simplejson python3-shapely python3-matplotlib gdal-hdf5 gdal-ecw gdal-mrsid gdal-oracle gdal-sosi python3-pygments qt5-tools python3-networkx python3-scipy python3-pyodbc python3-xlrd python3-xlwt setup python3-exifread python3-lxml python3-jinja2 python3-markupsafe python3-python-dateutil python3-pytz python3-nose2 python3-mock python3-httplib2 python3-pypiwin32 python3-future python3-pip python3-pillow python3-pandas python3-geographiclib grass saga-ltr
external-source: $P
EOF

	/bin/tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 \
		osgeo4w/package.sh \
		osgeo4w/patch \
		osgeo4w/msvc-env.bat \
		osgeo4w/postinstall.bat \
		osgeo4w/preremove.bat \
		osgeo4w/process.bat \
		osgeo4w/designer.bat \
		osgeo4w/python.bat \
		osgeo4w/qgis.bat \
		osgeo4w/qgis.reg.tmpl \
		osgeo4w/qgis.vars \
		osgeo4w/qgis-grass.bat
)

endlog
