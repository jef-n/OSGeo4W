export P=qgis-ltr-dev
export V=tbd
export B=tbd
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="expat-devel fcgi-devel proj-devel gdal-devel qt5-oci qt5-oci-debug sqlite3-devel geos-devel gsl-devel libiconv-devel libzip-devel libspatialindex-devel python3-pip python3-pyqt5 python3-sip python3-pyqt-builder python3-devel python3-qscintilla python3-nose2 python3-future python3-pyyaml python3-mock python3-six qca-devel qscintilla-devel qt5-devel qwt-devel libspatialite-devel oci-devel qtkeychain-devel zlib-devel opencl-devel exiv2-devel protobuf-devel python3-setuptools zstd-devel oci-devel qtwebkit-devel libpq-devel libxml2-devel hdf5-devel hdf5-tools netcdf-devel python3-pyqt-builder pdal pdal-devel grass8 transifex-cli"

: ${SITE:=qgis.org}
: ${TARGET:=Nightly}
: ${CC:=cl.exe}
: ${CXX:=cl.exe}
: ${BUILDCONF:=RelWithDebInfo}

REPO=https://github.com/qgis/QGIS.git

export SITE TARGET CC CXX BUILDCONF

source ../../../scripts/build-helpers

startlog

# Get latest release branch
RELBRANCH=$(git ls-remote --heads $REPO "refs/heads/release-*_*" | sed -e '/\^{}$/d' -ne 's#^.*refs/heads/release-#release-#p' | sort -V | tail -1)
RELBRANCH=${RELBRANCH#*/}

LTRTAG=$(git ls-remote --tags $REPO | sed -e '/\^{}$/d' -ne 's#^.*refs/tags/ltr-#ltr-#p' | sort -V | tail -1)
LTRBRANCH=release-${LTRTAG#ltr-}

if [ "$RELBRANCH" = "$LTRBRANCH" ]; then
        LTRTAG=$(git ls-remote --tags $REPO | sed -e '/\^{}$/d' -ne 's#^.*refs/tags/ltr-#ltr-#p' | sort -V | tail -2 | head -1)
	LTRBRANCH=release-${LTRTAG#ltr-}
	LABEL="previous long term release"
else
	LABEL="long term release"
fi

cd ..

if [ -d qgis ]; then
	cd qgis
	git config core.filemode false

	if [ -z "$OSGEO4W_SKIP_CLEAN" ]; then
		git fetch origin $LTRBRANCH
		git clean -f
		git reset --hard

		if [ "$(git branch --show-current)" != $LTRBRANCH ]; then
			if ! git checkout $LTRBRANCH; then
				git remote set-branches --add origin $LTRBRANCH
				git fetch origin $LTRBRANCH:$LTRBRANCH
				git checkout $LTRBRANCH
				git branch --set-upstream-to=origin/$LTRBRANCH $LTRBRANCH
			fi
		fi

		git config pull.rebase false
		git pull
	fi
else
	git clone $REPO --branch $LTRBRANCH --single-branch --depth 1 qgis
	cd qgis
	git config core.filemode false
fi

if [ -z "$OSGEO4W_SKIP_CLEAN" ]; then
	patch -p1 --dry-run <../osgeo4w/patch
	patch -p1 <../osgeo4w/patch
fi

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

(
	set -e
	set -x

	cd $OSGEO4W_PWD

	fetchenv osgeo4w/bin/o4w_env.bat

	vs2019env
	cmakeenv
	ninjaenv

	cd ../qgis

	if [ -n "$TX_TOKEN" ]; then
		if ! PATH=/bin:$PATH bash -x scripts/pull_ts.sh; then
			echo "TSPULL FAILED $?"
			rm -rf i18n doc/TRANSLATORS
			git checkout i18n doc/TRANSLATORS
		fi
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

	[ -f "$GRASS" ] || { echo GRASS not set; false; }
	[ -d "$GRASS_PREFIX" ] || { echo no directory GRASS_PREFIX $GRASS_PREFIX; false; }
	[ -d "$DBGHLP_PATH" ] || { echo no directory $DBGHLP_PATH $DBGHLP_PATH; false; }

	export GRASS_VERSION=$(cmd /c $GRASS --config version | sed -e "s/\r//")

	cd $BUILDDIR

	echo CMAKE: $(date)

	rm -f qgsversion.h
	touch $SRCDIR/CMakeLists.txt

	cmake -G Ninja \
		-D CMAKE_CXX_COMPILER="$(cygpath -m $CXX)" \
		-D CMAKE_C_COMPILER="$(cygpath -m $CC)" \
		-D CMAKE_LINKER=link.exe \
		-D SUBMIT_URL="https://cdash.orfeo-toolbox.org/submit.php?project=QGIS" \
		-D CMAKE_CXX_FLAGS_${BUILDCONF^^}="/MD /Z7 /MP /Od /D NDEBUG /std:c++17 /permissive-" \
		-D CMAKE_PDB_OUTPUT_DIRECTORY_${BUILDCONF^^}=$(cygpath -am $BUILDDIR/apps/$P/pdb) \
		-D BUILDNAME="$BUILDNAME" \
		-D SITE="$SITE" \
		-D PEDANTIC=TRUE \
		-D WITH_QSPATIALITE=TRUE \
		-D WITH_SERVER=TRUE \
		-D SERVER_SKIP_ECW=TRUE \
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
		-D SETUPAPI_LIBRARY="$SETUPAPI_LIBRARY" \
		-D PROJ_INCLUDE_DIR=$(cygpath -am $O4W_ROOT/include) \
		-D GEOS_LIBRARY=$(cygpath -am "$O4W_ROOT/lib/geos_c.lib") \
		-D SQLITE3_LIBRARY=$(cygpath -am "$O4W_ROOT/lib/sqlite3_i.lib") \
		-D SPATIALITE_LIBRARY=$(cygpath -am "$O4W_ROOT/lib/spatialite_i.lib") \
		-D SPATIALINDEX_LIBRARY=$(cygpath -am $O4W_ROOT/lib/spatialindex-64.lib) \
		-D Python_EXECUTABLE=$(cygpath -am $O4W_ROOT/bin/python3.exe) \
		-D SIP_MODULE_EXECUTABLE=$(cygpath -am $PYTHONHOME/Scripts/sip-module.exe) \
		-D PYUIC_PROGRAM=$(cygpath -am $PYTHONHOME/Scripts/pyuic5.exe) \
		-D PYRCC_PROGRAM=$(cygpath -am $PYTHONHOME/Scripts/pyrcc5.exe) \
		-D PYTHON_INCLUDE_PATH=$(cygpath -am $PYTHONHOME/include) \
		-D PYTHON_LIBRARY=$(cygpath -am $PYTHONHOME/libs/$(basename $PYTHONHOME).lib) \
		-D QT_LIBRARY_DIR=$(cygpath -am $O4W_ROOT/lib) \
		-D QT_HEADERS_DIR=$(cygpath -am $O4W_ROOT/apps/qt5/include) \
		-D CMAKE_INSTALL_PREFIX=$(cygpath -am $INSTDIR/apps/$P) \
		-D CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_NO_WARNINGS=TRUE \
		-D FCGI_INCLUDE_DIR=$(cygpath -am $O4W_ROOT/include) \
		-D FCGI_LIBRARY=$(cygpath -am $O4W_ROOT/lib/libfcgi.lib) \
		-D QCA_INCLUDE_DIR=$(cygpath -am $O4W_ROOT/apps/Qt5/include/QtCrypto) \
		-D QCA_LIBRARY=$(cygpath -am $O4W_ROOT/apps/Qt5/lib/qca-qt5.lib) \
		-D QWT_LIBRARY=$(cygpath -am $O4W_ROOT/apps/Qt5/lib/qwt.lib) \
		-D QSCINTILLA_LIBRARY=$(cygpath -am $O4W_ROOT/apps/Qt5/lib/qscintilla2.lib) \
		-D DART_TESTING_TIMEOUT=60 \
		-D PUSH_TO_CDASH=TRUE \
		$(cygpath -m $SRCDIR)

	if [ -z "$OSGEO4W_SKIP_CLEAN" ]; then
		echo CLEAN: $(date)
		cmake --build $(cygpath -am $BUILDDIR) --target clean --config $BUILDCONF
	fi

	mkdir -p $BUILDDIR/apps/$P/pdb

	echo ALL_BUILD: $(date)
	cmake --build $(cygpath -am $BUILDDIR) --target ${TARGET}Build --config $BUILDCONF
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
		echo RUN_TESTS: $(date)
		reg add "HKCU\\Software\\Microsoft\\Windows\\Windows Error Reporting" /v DontShow /t REG_DWORD /d 1 /f

		export TEMP=$TEMP/$P
		export TMP=$TEMP
		export TMPDIR=$TEMP

		rm -rf "$TEMP"
		mkdir -p $TEMP

		export PATH="$PATH:$(cygpath -au $GRASS_PREFIX/lib)"
		export GISBASE=$(cygpath -aw $GRASS_PREFIX)

		export PATH=$PATH:$(cygpath -au $BUILDDIR/output/plugins)
		export QT_PLUGIN_PATH="$(cygpath -au $BUILDDIR/output/plugins);$(cygpath -au $O4W_ROOT/apps/qt5/plugins)"

		rm -f ../testfailure
		if ! cmake --build $(cygpath -am $BUILDDIR) --target ${TARGET}Test --config $BUILDCONF; then
			echo TESTS FAILED: $(date)
			touch ../testfailure
		fi
	)
	fi

	cmake --build $(cygpath -am $BUILDDIR) --target ${TARGET}Submit --config $BUILDCONF || echo SUBMISSION FAILED

	if [ -z "$OSGEO4W_SKIP_INSTALL" ]; then
		rm -rf $INSTDIR
		mkdir -p $INSTDIR

		echo INSTALL: $(date)
		cmake --build $(cygpath -am $BUILDDIR) --target install --config $BUILDCONF

		echo PACKAGE: $(date)

		cd ..

		mkdir -p $INSTDIR/{etc/{postinstall,preremove},bin}

		v=$MAJOR.$MINOR.$PATCH

		SA=python/plugins/sagaprovider
		SAP=$SA/SagaAlgorithmProvider.py
		sagadef=$(sed -rne "s/^REQUIRED_VERSION *= *('.*')$/\\1/p" install/apps/$P/$SAP)
		sed -e "s/^REQUIRED_VERSION *= *'.*'$/REQUIRED_VERSION = @saga@/" install/apps/$P/$SAP >install/apps/$P/$SAP.tmpl

		sed -e "s/@package@/$P/g" -e "s/@version@/$v/g"                                                                                       qgis.reg.tmpl    >install/apps/$P/bin/qgis.reg.tmpl
		sed -e "s/@package@/$P/g" -e "s/@version@/$v/g" -e "s/@grassversion@/$GRASS_VERSION/g"                                                postinstall.bat  >install/etc/postinstall/$P.bat
		sed -e "s/@package@/$P/g" -e "s/@version@/$v/g" -e "s/@grassversion@/$GRASS_VERSION/g"                                                preremove.bat    >install/etc/preremove/$P.bat
		sed -e "s/@package@/$P/g" -e "s/@version@/$v/g" -e "s/@grassversion@/$GRASS_VERSION/g" -e "s/@grasspath@/$(basename $GRASS_PREFIX)/g" qgis.bat         >install/bin/$P.bat
		sed -e "s/@package@/$P/g" -e "s/@version@/$v/g"                                                                                       designer.bat     >install/bin/$P-designer.bat
		sed -e "s/@package@/$P/g" -e "s/@version@/$v/g"                                                                                       process.bat      >install/bin/qgis_process-$P.bat
		sed -e "s/@package@/$P/g" -e "s/@version@/$v/g"                                                                                       python.bat       >install/bin/python-$P.bat

		cat <<EOF >install/apps/$P/saga-refresh.bat
setlocal enabledelayedexpansion

set SAGA_VER=$sagadef

if exist "%OSGEO4W_ROOT%\\apps\\saga\\tools\\dev_tools.dll" (
	if not exist "%OSGEO4W_ROOT%\\apps\\$P\\$SA\\description.dist" (
		ren "%OSGEO4W_ROOT%\\apps\\$P\\$SA\\description" description.dist
		ren "%OSGEO4W_ROOT%\\apps\\$P\\$SA\\SagaNameDecorator.py" SagaNameDecorator.py.dist
	)

	"%OSGEO4W_ROOT%\\apps\\saga\\saga_cmd" dev_tools 7 -DIRECTORY "%OSGEO4W_ROOT%\\apps\\$P\\$SA" -CLEAR 0
	for /f "tokens=3 usebackq" %%a in (\`"%OSGEO4W_ROOT%\\apps\\saga\\saga_cmd" -v\`) do set v=%%a
	for /f "tokens=1,2 delims=." %%a in ("!v!") do set SAGA_VER='%%a.%%b.'
	del "%OSGEO4W_ROOT%\\apps\\$P\\$SA\\readme.txt"
) else if exist "%OSGEO4W_ROOT%\\apps\\$P\\$SA\\description.dist" (
	rmdir /s /q "%OSGEO4W_ROOT%\\apps\\$P\\$SA\\description"
	del "%OSGEO4W_ROOT%\\apps\\$P\\$SA\\SagaNameDecorator.py"

	ren "%OSGEO4W_ROOT%\\apps\\$P\\$SA\\description.dist" description
	ren "%OSGEO4W_ROOT%\\apps\\$P\\$SA\\SagaNameDecorator.py.dist" SagaNameDecorator.py.dist
)

textreplace ^
	-sf "%OSGEO4W_ROOT%\\apps\\$P\\$SAP.tmpl" ^
	-df "%OSGEO4W_ROOT%\\apps\\$P\\$SAP" ^
	-map @saga@ "%SAGA_VER%"

endlocal
EOF

		cp "$DBGHLP_PATH"/{dbghelp.dll,symsrv.dll} install/apps/$P

		mkdir -p install/apps/$P/python
		cp "$PYTHONHOME/Lib/site-packages/PyQt5/uic/widget-plugins/qgis_customwidgets.py" install/apps/$P/python

		export R=$OSGEO4W_REP/x86_64/release/qgis/$P
		mkdir -p $R/$P-{pdb,full-free,full,deps}

		touch exclude
		cp ../qgis/COPYING $R/$P-$V-$B.txt
		/bin/tar -cjf $R/$P-$V-$B.tar.bz2 \
			--exclude-from exclude \
			--exclude "*.pyc" \
			--exclude "install/apps/$P/$SAP" \
			--xform "s,^qgis.vars,bin/$P-bin.vars," \
			--xform "s,^osgeo4w/apps/qt5/plugins/,apps/$P/qtplugins/," \
			--xform "s,^install/apps/$P/bin/qgis.exe,bin/$P-bin.exe," \
			--xform "s,^install/,," \
			--xform "s,^install$,.," \
			qgis.vars \
			osgeo4w/apps/qt5/plugins/sqldrivers/qsqlocispatial.dll \
			osgeo4w/apps/qt5/plugins/sqldrivers/qsqlspatialite.dll \
			osgeo4w/apps/qt5/plugins/designer/qgis_customwidgets.dll \
			install/

		/bin/tar -C $BUILDDIR --remove-files -cjf $R/$P-pdb/$P-pdb-$V-$B.tar.bz2 \
			apps/$P/pdb

		d=$(mktemp -d)
		cp ../qgis/COPYING $R/$P-full-free/$P-full-free-$V-$B.txt
		/bin/tar -C $d -cjf $R/$P-full-free/$P-full-free-$V-$B.tar.bz2 .
		cp ../qgis/COPYING $R/$P-full/$P-full-$V-$B.txt
		/bin/tar -C $d -cjf $R/$P-full/$P-full-$V-$B.tar.bz2 .
		cp ../qgis/COPYING $R/$P-deps/$P-deps-$V-$B.txt
		/bin/tar -C $d -cjf $R/$P-deps/$P-deps-$V-$B.tar.bz2 .
		rmdir $d

		cat <<EOF >$R/setup.hint
sdesc: "QGIS nightly build of the $LABEL branch"
ldesc: "QGIS nightly build of the $LABEL branch"
maintainer: $MAINTAINER
category: Desktop
requires: msvcrt2019 $RUNTIMEDEPENDS libpq geos zstd gsl gdal libspatialite zlib libiconv fcgi libspatialindex oci qt5-libs qt5-qml qt5-tools qtwebkit-libs qca qwt-libs python3-sip python3-core python3-pyqt5 python3-psycopg2-binary python3-qscintilla python3-jinja2 python3-markupsafe python3-pygments python3-python-dateutil python3-pytz python3-nose2 python3-mock python3-httplib2 python3-future python3-pyyaml python3-gdal python3-requests python3-plotly python3-pyproj python3-owslib qtkeychain-libs libzip opencl exiv2 hdf5 pdal pdal-libs
EOF

		appendversions $R/setup.hint

		cat <<EOF >$R/$P-pdb/setup.hint
sdesc: "Debugging symbols for QGIS nightly build of the $LABEL branch"
ldesc: "Debugging symbols for QGIS nightly build of the $LABEL branch"
maintainer: $MAINTAINER
category: Desktop
requires: $P
external-source: $P
EOF

		appendversions $R/$P-pdb/setup.hint

		cat <<EOF >$R/$P-full-free/setup.hint
sdesc: "QGIS nightly build of the $LABEL branch (metapackage with additional free dependencies)"
ldesc: "QGIS nightly build of the $LABEL branch (metapackage with additional free dependencies)"
maintainer: $MAINTAINER
category: Desktop
requires: $P proj python3-pyparsing python3-simplejson python3-shapely python3-matplotlib python3-pygments qt5-tools python3-networkx python3-scipy python3-pyodbc python3-xlrd python3-xlwt setup python3-exifread python3-lxml python3-jinja2 python3-markupsafe python3-python-dateutil python3-pytz python3-nose2 python3-mock python3-httplib2 python3-pypiwin32 python3-future python3-pip python3-pillow python3-geopandas python3-geographiclib grass8 python3-pyserial gdal-sosi saga python3-openpyxl python3-remotior-sensus
external-source: $P
EOF

		appendversions $R/$P-full-free/setup.hint

		cat <<EOF >$R/$P-full/setup.hint
sdesc: "QGIS nightly build of the $LABEL branch (metapackage with additional dependencies including proprietary)"
ldesc: "QGIS nightly build of the $LABEL branch (metapackage with additional dependencies including proprietary)"
maintainer: $MAINTAINER
category: Desktop
requires: $P-full-free gdal-hdf5 gdal-mss gdal-ecw gdal-mrsid gdal-oracle
external-source: $P
EOF

		appendversions $R/$P-full/setup.hint

		cat <<EOF >$R/$P-deps/setup.hint
sdesc: "QGIS build dependencies of nightly build of $LABEL branch (meta package)"
ldesc: "QGIS build dependencies of nightly build of $LABEL branch (meta package)"
maintainer: $MAINTAINER
category: Libs
requires: $BUILDDEPENDS
external-source: $P
EOF

		appendversions $R/$P-deps/setup.hint

		/bin/tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 \
			osgeo4w/package.sh \
			osgeo4w/msvc-env.bat \
			osgeo4w/process.bat \
			osgeo4w/designer.bat \
			osgeo4w/python.bat \
			osgeo4w/qgis.bat \
			osgeo4w/qgis.vars \
			osgeo4w/qgis.reg.tmpl \
			osgeo4w/postinstall.bat \
			osgeo4w/preremove.bat \
			osgeo4w/patch
	fi
)

endlog
