export P=qt6
export V=6.6.3
export B="next qt6-libs"
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-core python3-pip openssl-devel sqlite3-devel zlib-devel libjpeg-turbo-devel libtiff-devel libpng-devel oci-devel libwebp-devel libmysql-devel zstd-devel libpq-devel icu-devel freetype-devel node"
export PACKAGES="qt6-devel qt6-docs qt6-libs-symbols qt6-oci qt6-qml qt6-tools"

source ../../../scripts/build-helpers

startlog

[ -f qt-everywhere-src-$V.tar.xz ] || wget https://download.qt.io/official_releases/qt/${V%.*}/$V/single/qt-everywhere-src-$V.tar.xz
mkdir -p build/s
[ -f build/s/CMakeLists.txt ] || tar --xform "s,^qt-everywhere-src-$V,build/s," -xJf qt-everywhere-src-$V.tar.xz
[ -f build/s/patched ] || (
	cd build/s
	patch -p1 --dry-run <../../patch
	patch -p1 <../../patch >patched
)

[ -f build/b/installed ] || {
	(
		set -e

		fetchenv osgeo4w/bin/o4w_env.bat

		vsenv
		cmakeenv
		ninjaenv

		type -a cmake ninja
		cmake --version
		ninja --version

		pip3 install html5lib

		# TODO: why don't cygwin's and msys' gperfs work
		[ -x osgeo4w/bin/gperf.exe ] || {
			[ -f gperf-3.0.1.zip ] || curl -O https://altushost-swe.dl.sourceforge.net/project/gnuwin32/gperf/3.0.1/gperf-3.0.1-bin.zip
			unzip -p gperf-3.0.1-bin.zip bin/gperf.exe >osgeo4w/bin/gperf.exe
			chmod a+rx osgeo4w/bin/gperf.exe
			type -a gperf
			gperf -v
		}

		export PATH=$OSGEO4W_PWD/osgeo4w/apps/node:$PATH
		unset PYTHONUTF8

		mkdir -p build/{b,i}	# build install

		if [ -f build/b/subst ]; then
			SUBST=$(<build/b/subst)
			d=${SUBST#/cygdrive/}
			subst $d: $(cygpath -aw build)
		else
			SUBST=
			for d in {a..z}; do
				if subst $d: $(cygpath -aw build); then
					SUBST=$(cygpath -a $d:\\)
					SUBST=${SUBST%/}
					break
				fi
			done
			if [ -z "$SUBST" ] || ! [ -d $SUBST/b ]; then
				log "No build drive substituted"
				exit 1
			fi
			echo $SUBST >build/b/subst
		fi

		echo "Substituted directory: $SUBST"
		trap "subst $d: /d || { echo subst failed; subst; }" EXIT

		cd $SUBST/b

		export INCLUDE="$(cygpath -aw $OSGEO4W_PWD/osgeo4w/include);$(cygpath -aw "$(find $VCINSTALLDIR -iname atlbase.h -printf '%h')");$INCLUDE"
		export LIB="$(cygpath -aw $OSGEO4W_PWD/osgeo4/lib);$(cygpath -aw "$(find $VCINSTALLDIR -path "*/x64/*" -iname atls.lib -printf '%h')");$LIB"

		[ -f build.ninja ] || {
			CMAKE_INCLUDE_PATH=$(cygpath -am $OSGEO4W_PWD/osgeo4w/include) \
			CMAKE_LIBRARY_PATH=$(cygpath -am $OSGEO4W_PWD/osgeo4w/lib) \
			cmd /c ..\\s\\configure.bat \
				-prefix $(cygpath -aw ../i) \
				-force-debug-info \
				-skip qtopcua \
				-system-sqlite \
				-system-tiff \
				-system-webp \
				-system-libpng \
				-system-libjpeg \
				-system-zlib \
				-system-freetype \
				-- \
				-D SQLite3_LIBRARY=$(cygpath -am $OSGEO4W_ROOT/lib/sqlite3_i.lib)
		}

		[ -f built ] || {
			cmake --build . --parallel -- -k0 || cmake --build . --parallel
			touch built
		}

		[ -f installed ] || {
			cmake --install .
			touch installed
		}
	)
}

set -e

cd build/i

rm -f ../{tools,libs,devel,symbols,docs,qml,oci,filelist}

find -type f >../filelist
rm -f ../unknown

# classify files
while read f; do
        e=${f##*.}

	p=unknown
        case "$e" in
        exe)
		case "${f,,}" in
		./bin/assistant.exe|\
		./bin/designer.exe|\
		./bin/linguist.exe)
			p=tools
			;;

		./bin/*process.exe)
			p=libs
			;;

		./bin/qml*)
			p=qml
			;;

		*)
			p=devel
			;;
		esac
                ;;

        prl|lib|pl|h)
                p=devel
                ;;

        dll|pdb)
		case "$f" in
		./plugins/sqldrivers/qsqloci*)
			p=oci
			;;

		./qml/*)
			p=qml
			;;

		*)
			if [ "$e" = "dll" ]; then
				p=libs
			else
				p=symbols
			fi
			;;
		esac
		;;

	qm)
		case "$f" in
		./translations/assistant_*|\
		./translations/linguist_*|\
		./translations/designer_*)
			p=tools
			;;

		./translations/qt_*|\
		./translations/qtbase_*|\
		./translations/qtconnectivity_*|\
		./translations/qtdeclarative_*|\
		./translations/qtlocation_*|\
		./translations/qtmultimedia_*|\
		./translations/qtserialport_*|\
		./translations/qtscript_*|\
		./translations/qtwebsockets_*|\
		./translations/qtxmlpatterns_*|\
		./translations/qtwebengine_*)
			p=libs
			;;

		./translations/qtquickcontrols*)
			p=qml
			;;

		*)
			;;

		esac
		;;

        *)
		case "$f" in
		./doc/*)
			p=docs
			;;

		./include/*|\
		./lib/cmake/*|\
		./mkspecs/*|\
		./phrasebooks/*)
			p=devel
			;;

		./qml/*)
			p=qml
			;;

		./resources/icudtl.dat|\
		./resources/qtwebengine*|\
		./translations/qtwebengine_locales/*|\
		./translations/catalogs.json|\
		./resources/v8_context_snapshot.bin)
			p=libs
			;;

		./bin/android_emulator_launcher.sh|\
		./bin/ensure_pro_file.cmake|\
		./bin/qt-cmake-create.bat|\
		./bin/qt-cmake-private-install.cmake|\
		./bin/qt-cmake-private.bat|\
		./bin/qt-cmake-standalone-test.bat|\
		./bin/qt-cmake.bat|\
		./bin/qt-configure-module.bat|\
		./bin/qt-internal-configure-tests.bat|\
		./bin/qt-testrunner.py|\
		./bin/sanitizer-testrunner.py|\
		./metatypes/*_metatypes.json|\
		./modules/*.json|\
		./lib/*.obj)
			p=devel
			;;

		*)
			;;
		esac

        esac

        echo $f >>../$p
done <../filelist

if [ -s  ../unknown ]; then
	echo $(wc -l ../unknown) unknown files
	exit 1
fi

set -x

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-{devel,qml,tools,docs,libs,libs-symbols,oci}

#
# libs (files + ini bat + qt.conf)
#

cat <<EOF >../$P.bat
@echo off
call set path=%%path:%OSGEO4W_ROOT%\\apps\\Qt5\\bin=%%

path %OSGEO4W_ROOT%\\apps\\$P\\bin;%PATH%

set QT_PLUGIN_PATH=%OSGEO4W_ROOT%\\apps\\${P^}\\plugins

set O4W_QT_PREFIX=%OSGEO4W_ROOT:\\=/%/apps/${P^}
set O4W_QT_BINARIES=%OSGEO4W_ROOT:\\=/%/apps/${P^}/bin
set O4W_QT_PLUGINS=%OSGEO4W_ROOT:\\=/%/apps/${P^}/plugins
set O4W_QT_LIBRARIES=%OSGEO4W_ROOT:\\=/%/apps/${P^}/lib
set O4W_QT_TRANSLATIONS=%OSGEO4W_ROOT:\\=/%/apps/${P^}/translations
set O4W_QT_HEADERS=%OSGEO4W_ROOT:\\=/%/apps/${P^}/include
set O4W_QT_DOC=%OSGEO4W_ROOT:\\=/%/apps/${P^}/doc
EOF

cat <<EOF >../$P.conf
[Paths]
Prefix=\$(O4W_QT_PREFIX)
Binaries=\$(O4W_QT_BINARIES)
Plugins=\$(O4W_QT_PLUGINS)
Libraries=\$(O4W_QT_LIBRARIES)
Translations=\$(O4W_QT_TRANSLATIONS)
Headers=\$(O4W_QT_HEADERS)
Documentation=\$(O4W_QT_DOC)
EOF

cat <<EOF >$R/$P-libs/setup.hint
sdesc: "${P^} runtime libraries"
ldesc: "${P^} runtime libraries"
maintainer: $MAINTAINER
category: Libs
requires: base msvcrt2019 openssl sqlite3 zlib libjpeg-turbo libtiff libpng libwebp libmysql zstd libpq icu freetype
external-source: $P
EOF

tar -cjf $R/$P-libs/$P-libs-$V-$B.tar.bz2 \
	--absolute-names \
	--xform s,^../$P.bat,bin/${P}_env.bat, \
	--xform s,^../$P.conf,bin/qt.conf, \
	--xform s,^.././$P.conf,apps/$P/bin/qt.conf, \
	--xform s,^./,apps/$P/, \
	../$P.bat \
	../$P.conf \
	.././$P.conf \
	-T ../libs

#
# libs-symbols
#

cat <<EOF >$R/$P-libs-symbols/setup.hint
sdesc: "${P^} runtime libraries (release version; symbol files)"
ldesc: "${P^} runtime libraries (release version; symbol files)"
maintainer: $MAINTAINER
category: Libs
requires: $P-libs
external-source: $P
EOF

tar -cjf $R/$P-libs-symbols/$P-libs-symbols-$V-$B.tar.bz2 \
	--xform s,^./,apps/$P/, \
	-T ../symbols

#
# oci
#

cat <<EOF >$R/$P-oci/setup.hint
sdesc: "${P^} OCI SQL plugin"
ldesc: "${P^} OCI SQL plugin"
maintainer: $MAINTAINER
category: Libs
requires: $P-libs oci
external-source: $P
EOF

tar -cjf $R/$P-oci/$P-oci-$V-$B.tar.bz2 \
	--xform s,^./,apps/$P/, \
	-T ../oci


#
# tools
#

cat <<EOF >$R/$P-tools/setup.hint
sdesc: "${P^} tools (Development)"
ldesc: "${P^} tools (Development)"
maintainer: $MAINTAINER
category: Desktop Commandline_Utilities
requires: $P-libs
external-source: $P
EOF

tar -cjf $R/$P-tools/$P-tools-$V-$B.tar.bz2 \
	--xform s,^./,apps/$P/, \
	-T ../tools

#
# devel
#

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "${P^} headers and libraries (Development)"
ldesc: "${P^} headers and libraries (Development)"
maintainer: $MAINTAINER
category: Libs
requires: $P-libs
external-source: $P
EOF

tar -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	--xform s,^./,apps/$P/, \
	-T ../devel

#
# documentation (TODO; requires sphinx for Python2?)
#

cat <<EOF >$R/$P-docs/setup.hint
sdesc: "${P^} documentation (Development)"
ldesc: "${P^} documentation (Development)"
maintainer: $MAINTAINER
category: Libs
requires: 
external-source: $P
EOF

tar -cjf $R/$P-docs/$P-docs-$V-$B.tar.bz2 \
	--xform s,^./,apps/$P/, \
	-T ../docs

#
# QtQuick / QML
#

cat <<EOF >$R/$P-qml/setup.hint
sdesc: "${P^} QML"
ldesc: "${P^} QML"
maintainer: $MAINTAINER
category: Libs
requires: $P-libs
external-source: $P
EOF

tar -cjf $R/$P-qml/$P-qml-$V-$B.tar.bz2 \
	--xform s,^./,apps/$P/, \
	-T ../qml

#
# source
#

tar -cjf $R/$P-$V-$B-src.tar.bz2 \
	-C ../../.. \
	osgeo4w/package.sh

#
# license
#

for i in devel qml tools docs libs libs-symbols oci; do
	cp ../s/LICENSE.GPL3 $R/$P-$i/$P-$i-$V-$B.txt
done

#
# check
#

for i in devel qml tools docs libs libs-symbols oci; do
	tar -tjf $R/$P-$i/$P-$i-$V-$B.tar.bz2
done >../installed

sort ../installed | uniq -d >../dupes || true
if [ -s ../dupes ]; then
	echo Duplicate packaged files:
	cat ../dupes
fi

sort <(sed -e "s#^\./#apps/$P/#" ../filelist) ../installed | uniq -u | fgrep -v -x -f <(cat <<EOF
bin/qt.conf
apps/$P/bin/qt.conf
bin/${P}_env.bat
EOF
) >../not-installed || true

if [ -s ../not-installed ]; then
	echo Not packaged files:
	cat ../not-installed
fi

! [ -s ../dupes ] && ! [ -s ../not-installed ]

endlog
