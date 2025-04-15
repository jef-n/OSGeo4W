export P=qgis-dev
export V=tbd
export B=tbd
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="expat-devel fcgi-devel proj-devel gdal-dev-devel qt5-oci sqlite3-devel geos-devel gsl-devel libiconv-devel libzip-devel libspatialindex-devel python3-pip python3-pyqt5 python3-sip python3-pyqt-builder python3-devel python3-qscintilla python3-nose2 python3-future python3-pyyaml python3-mock python3-six qca-devel qscintilla-devel qt5-devel qwt-devel libspatialite-devel oci-devel qtkeychain-devel zlib-devel opencl-devel exiv2-devel protobuf-devel python3-setuptools zstd-devel qtwebkit-devel libpq-devel libxml2-devel hdf5-devel hdf5-tools netcdf-devel pdal pdal-devel grass draco-devel libtiff-devel transifex-cli python3-oauthlib"
export PACKAGES="qgis-dev qgis-dev-deps qgis-dev-full qgis-dev-full-free qgis-dev-pdb"

: ${REPO:=https://github.com/qgis/QGIS.git}
: ${SITE:=qgis.org}
: ${TARGET:=Nightly}
: ${CC:=cl.exe}
: ${CXX:=cl.exe}
: ${BUILDCONF:=RelWithDebInfo}
: ${PUSH_TO_DASH:=TRUE}

export SITE TARGET CC CXX BUILDCONF

source ../../../scripts/build-helpers

startlog

BRANCH=
if [ -z "$REF" ]; then
	BRANCH=master
	APPNAME="Nightly"
	PKGDESC="QGIS Nightly build of development branch"
else
	: ${PKGDESC:="QGIS build of development branch ($REF)"}
	: ${APPNAME:=$P/$REF}
fi

cd ..

if [ -d qgis ]; then
	cd qgis
	git config core.filemode false

	if [ -z "$OSGEO4W_SKIP_CLEAN" ]; then
		git clean -f
		git reset --hard

		git config pull.rebase false

		i=0
		until (( i > 10 )) || git pull; do
			(( ++i ))
		done
	fi
elif [ -n "$BRANCH" ]; then
	git clone $REPO --branch $BRANCH --single-branch --depth 1 qgis
	cd qgis
	git config core.filemode false
	unset OSGEO4W_SKIP_CLEAN
elif [ -n "$REF" ]; then
	set -x
	mkdir qgis
	cd qgis
	git init .
	git remote add origin $REPO
	git fetch --no-tags --prune --no-recurse-submodules --depth=1 origin +$REF:refs/remotes/${REF#refs/}
	git checkout --force refs/remotes/${REF#refs/}
	git log -1 --format='%H'
	unset OSGEO4W_SKIP_CLEAN
else
	echo REF expected
	exit 1
fi

if [ -z "$OSGEO4W_SKIP_CLEAN" ]; then
	if ! git apply --allow-empty --check --reverse ../osgeo4w/patch; then
		git apply --allow-empty --check ../osgeo4w/patch
		git apply --allow-empty ../osgeo4w/patch
	fi
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
		(( ++build ))
	fi
fi

V=$V-$build-$SHA
nextbinary

(
	set -e
	set -x

	cd $OSGEO4W_PWD

	fetchenv osgeo4w/bin/o4w_env.bat
	fetchenv osgeo4w/bin/gdal-dev-env.bat

	vsenv
	cmakeenv
	ninjaenv
	ccacheenv

	cd ../qgis

	if [ -n "$TX_TOKEN" ]; then
		perl -MLocales -e 1 2>/dev/null || cpan -T install Locales </dev/null
		if ! PATH=/bin:$PATH bash -x scripts/pull_ts.sh; then
			echo "TSPULL FAILED $?"
			rm -rf i18n doc/TRANSLATORS
			git checkout i18n doc/TRANSLATORS
		fi
	fi

	cd ../osgeo4w

	export BUILDNAME=$P-$V-$TARGET-VC17
	export QGIS_CONTINUOUS_INTEGRATION_RUN=true
	export BUILDDIR=$PWD/build
	export INSTDIR=$PWD/install
	export SRCDIR=$(cygpath -am ../qgis)
	export O4W_ROOT=$(cygpath -am osgeo4w)
	export LIB_DIR=$(cygpath -aw osgeo4w)

	mkdir -p $BUILDDIR

	unset PYTHONPATH
	export INCLUDE="$(cygpath -aw $OSGEO4W_ROOT/apps/Qt5/include);$(cygpath -aw $OSGEO4W_ROOT/apps/gdal-dev/include);$(cygpath -aw $OSGEO4W_ROOT/include);$INCLUDE"
	export LIB="$(cygpath -aw $OSGEO4W_ROOT/apps/Qt5/lib);$(cygpath -aw $OSGEO4W_ROOT/apps/gdal-dev/lib);$(cygpath -aw $OSGEO4W_ROOT/lib);$LIB"

	export GRASS=$(cygpath -aw $O4W_ROOT/bin/grass*.bat)
	export GRASS_VERSION=$(unset SHELL; cmd /c $GRASS --config version | sed -e "s/\r//")
	export GRASS_PREFIX=$(unset SHELL; cmd /c $GRASS --config path | sed -e "s/\r//")

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
		-D CMAKE_SHARED_LINKER_FLAGS_${BUILDCONF^^}="/INCREMENTAL:NO /DEBUG /OPT:REF /OPT:ICF" \
		-D CMAKE_MODULE_LINKER_FLAGS_${BUILDCONF^^}="/INCREMENTAL:NO /DEBUG /OPT:REF /OPT:ICF" \
		-D CMAKE_PDB_OUTPUT_DIRECTORY_${BUILDCONF^^}=$(cygpath -am $BUILDDIR/apps/$P/pdb) \
		-D BUILDNAME="$BUILDNAMEPREFIX$BUILDNAME" \
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
		-D HAS_KDE_QT5_PDF_TRANSFORM_FIX=TRUE \
		-D HAS_KDE_QT5_SMALL_CAPS_FIX=TRUE \
		-D HAS_KDE_QT5_FONT_STRETCH_FIX=TRUE \
		-D SETUPAPI_LIBRARY="$(cygpath -am "/cygdrive/c/Program Files (x86)/Windows Kits/10/Lib/$UCRTVersion/um/x64/SetupAPI.Lib")" \
		-D PROJ_INCLUDE_DIR=$(cygpath -am $O4W_ROOT/include) \
		-D POSTGRES_INCLUDE_DIR=$(cygpath -am $O4W_ROOT/include) \
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
		-D PUSH_TO_CDASH=$PUSH_TO_DASH \
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
		export QT_PLUGIN_PATH="$(cygpath -aw $BUILDDIR/output/plugins);$(cygpath -aw $O4W_ROOT/apps/qt5/plugins)"

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
		cmakefix $INSTDIR

		echo PACKAGE: $(date)

		cd ..

		mkdir -p $INSTDIR/{etc/{postinstall,preremove},bin}

		v=$MAJOR.$MINOR.$PATCH

		sed -e "s/@package@/$P/g" -e "s/@version@/$v/g"                                                                                       qgis.reg.tmpl    >install/apps/$P/bin/qgis.reg.tmpl
		sed -e "s/@package@/$P/g" -e "s/@version@/$v/g" -e "s/@appname@/${APPNAME//\//\\\/}/g" -e "s/@grassversion@/$GRASS_VERSION/g"         postinstall.bat  >install/etc/postinstall/$P.bat
		sed -e "s/@package@/$P/g" -e "s/@version@/$v/g" -e "s/@appname@/${APPNAME//\//\\\/}/g" -e "s/@grassversion@/$GRASS_VERSION/g"         preremove.bat    >install/etc/preremove/$P.bat
		sed -e "s/@package@/$P/g" -e "s/@version@/$v/g"                                                                                       designer.bat     >install/bin/$P-designer.bat
		sed -e "s/@package@/$P/g" -e "s/@version@/$v/g"                                                                                       python.bat       >install/bin/python-$P.bat

		sed -e "s/@package@/$P/g" -e "s/@version@/$v/g" -e "s/@grassversion@/$GRASS_VERSION/g" -e "s/@grasspath@/$(basename $GRASS_PREFIX)/g" -e "s/@grassmajor@/${GRASS_VERSION%%.*}/" qgis.bat         >install/bin/$P.bat
		sed -e "s/@package@/$P/g" -e "s/@version@/$v/g" -e "s/@grassversion@/$GRASS_VERSION/g" -e "s/@grasspath@/$(basename $GRASS_PREFIX)/g" -e "s/@grassmajor@/${GRASS_VERSION%%.*}/" process.bat      >install/bin/qgis_process-$P.bat

		cp "/cygdrive/c/Program Files (x86)/Windows Kits/10/Debuggers/x64/"{dbghelp.dll,symsrv.dll} install/apps/$P

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
sdesc: "$PKGDESC"
ldesc: "$PKGDESC"
maintainer: $MAINTAINER
category: Desktop
requires: msvcrt2019 $RUNTIMEDEPENDS libpq geos zstd gsl gdal-dev libspatialite zlib libiconv fcgi libspatialindex oci qt5-libs qt5-qml qt5-tools qtwebkit-libs qca qwt-libs python3-sip python3-core python3-pyqt5 python3-psycopg2 python3-qscintilla python3-jinja2 python3-markupsafe python3-pygments python3-python-dateutil python3-pytz python3-nose2 python3-mock python3-httplib2 python3-future python3-pyyaml python3-gdal-dev python3-requests python3-plotly python3-pyproj python3-owslib qtkeychain-libs libzip opencl exiv2 hdf5 pdal pdal-libs
EOF

		appendversions $R/setup.hint

		cat <<EOF >$R/$P-pdb/setup.hint
sdesc: "$PKGDESC (debugging symbols)"
ldesc: "$PKGDESC (debugging symbols)"
maintainer: $MAINTAINER
category: Desktop
requires: $P
external-source: $P
EOF

		appendversions $R/$P-pdb/setup.hint

		cat <<EOF >$R/$P-full-free/setup.hint
sdesc: "$PKGDESC (metapackage with additional free dependencies)"
ldesc: "$PKGDESC (metapackage with additional free dependencies)"
maintainer: $MAINTAINER
category: Desktop
requires: $P proj python3-pyparsing python3-simplejson python3-shapely python3-matplotlib python3-pygments python3-networkx python3-scipy python3-pyodbc python3-xlrd python3-xlwt setup python3-exifread python3-lxml python3-jinja2 python3-markupsafe python3-python-dateutil python3-pytz python3-nose2 python3-mock python3-httplib2 python3-pypiwin32 python3-future python3-pip python3-pillow python3-geopandas python3-geographiclib grass python3-pyserial python3-autopep8 python3-openpyxl python3-remotior-sensus saga python3-pyarrow qt5-tools gdal-dev-sosi
external-source: $P
EOF

		appendversions $R/$P-full-free/setup.hint

		cat <<EOF >$R/$P-full/setup.hint
sdesc: "$PKGDESC (metapackage with additional dependencies including proprietary)"
ldesc: "$PKGDESC (metapackage with additional dependencies including proprietary)"
maintainer: $MAINTAINER
category: Desktop
requires: $P-full-free gdal-dev-hdf5 gdal-dev-ecw gdal-dev-mrsid gdal-dev-oracle
external-source: $P
EOF

		appendversions $R/$P-full/setup.hint

		cat <<EOF >$R/$P-deps/setup.hint
sdesc: "$PKGDESC (meta package of build dependencies)"
ldesc: "$PKGDESC (meta package of build dependencies)"
maintainer: $MAINTAINER
category: Libs
requires: $BUILDDEPENDS
external-source: $P
EOF

		appendversions $R/$P-deps/setup.hint

		/bin/tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 \
			osgeo4w/package.sh \
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
