export P=qt5
export V=tbd
export B=tbd
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="openssl-devel sqlite3-devel zlib-devel libjpeg-turbo-devel libtiff-devel libpng-devel oci-devel libwebp-devel libmysql-devel zstd-devel libpq-devel icu-devel freetype-devel node"
export PACKAGES="qt5-devel qt5-docs qt5-libs-symbols qt5-oci qt5-qml qt5-tools"

# perl also used in openssl and libpq
SBPERL=5.32.0.1
PY2=2.7.18
GITREPO=https://invent.kde.org/qt/qt/qt5.git

source ../../../scripts/build-helpers

startlog

if ! [ -d ../qt5 ]; then
	git clone $GITREPO ../qt5
	cd ../qt5
	git checkout kde/5.15
	perl init-repository
else
	cd ../qt5
	git submodule foreach git reset --hard
	git submodule update --recursive
fi

SHA=$(git log -n1 --pretty=%h)

# Fix for MSSQL change (https://github.com/qgis/QGIS/issues/50865)
patch -p1 --dry-run <../osgeo4w/patch
patch -p1 <../osgeo4w/patch

chmod a+x gnuwin32/bin/*.exe

export V=$(sed -ne "s/MODULE_VERSION *= *\([^ ]*\) *$/\1/p" qtbase/.qmake.conf)
nextbinary qt5-libs

cd ../osgeo4w

[ -f python-$PY2.amd64.msi ] || wget -q https://www.python.org/ftp/python/$PY2/python-$PY2.amd64.msi
[ -d py2 ] || cygstart --action=runas --wait msiexec /i $(cygpath -aw python-$PY2.amd64.msi) /quiet /norestart TARGETDIR=$(cygpath -aw py2) ALLUSERS=0 ADDLOCAL=DefaultFeature
[ -d py2 ]

if ! [ -d perl ]; then
        wget -c http://strawberryperl.com/download/$SBPERL/strawberry-perl-$SBPERL-64bit-portable.zip
        mkdir perl
        cd perl
        unzip ../strawberry-perl-$SBPERL-64bit-portable.zip
        cd ..
fi

export PATH="$(cygpath -a py2):$PATH:/bin:/usr/bin"

vsenv
cmakeenv
ninjaenv

# meet cute expectations
cp osgeo4w/lib/sqlite3_i.lib osgeo4w/lib/sqlite3.lib
for i in osgeo4w/lib/libwebp*.lib; do cp $i ${i/libwebp/webp}; done

mkdir -p build install

cd build

[ -f jom.exe ] || {
	wget -q http://download.qt.io/official_releases/jom/jom_1_1_3.zip
	unzip jom_1_1_3.zip jom.exe
	chmod a+rx jom.exe
}

export DESTDIR=../install
export APPDIR=$DESTDIR/apps/$P
export O4W=../osgeo4w
export INCLUDE="$(cygpath -aw $O4W/include);$(cygpath -aw "$(find $VCINSTALLDIR -iname atlbase.h -printf '%h')");$INCLUDE"
export LIB="$(cygpath -aw $O4W/lib);$(cygpath -aw "$(find $VCINSTALLDIR -path "*/x64/*" -iname atls.lib -printf '%h')");$LIB"

[ -f ../installed ] || {
	(
		fetchenv ../perl/portableshell.bat /SETENV

		export PATH=$(cygpath -a $O4W/apps/node):$PATH

		cmd /c ..\\..\\$P\\configure.bat -v \
			-opensource \
			-confirm-license \
			-release \
			-force-debug-info \
			-separate-debug-info \
			-nomake tests \
			-nomake examples \
			-prefix $(cygpath -aw $APPDIR) \
			-platform win32-msvc \
			-system-zlib \
			-system-libjpeg \
			-system-libpng \
			-system-webp \
			-system-tiff \
			-system-sqlite \
			-system-freetype \
			-openssl-linked \
			-sql-odbc \
			-sql-psql \
			-plugin-sql-oci \
			-plugin-sql-mysql \
			-icu \
			-mp

		export PATH=$(cygpath -a $O4W/bin):$PATH

		# build everything and maybe to the first error
		[ -f ../built ] || {
			./jom /k || ./jom /j1
			touch ../built
			rm -f ../installed
		}

		[ -f ../installed ] || {
			./jom install
			cmakefix $DESTDIR
			touch ../installed
			rm -f /tmp/qt.files
		}

	)
}

cd ../install

rm -f /tmp/{tools,libs,devel,symbols,docs,qml,oci}

[ -f /tmp/qt.files ] || find apps -type f >/tmp/qt.files
rm -f /tmp/qt.unknown

# classify files
while read f; do
        e=${f##*.}

        case "$e" in
        exe)
		case "${f,,}" in
		apps/qt5/bin/assistant.exe|\
		apps/qt5/bin/designer.exe|\
		apps/qt5/bin/linguist.exe)
			p=tools
			;;

		apps/qt5/bin/*process.exe)
			p=libs
			;;

		apps/qt5/bin/qml*)
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
		apps/qt5/plugins/sqldrivers/qsqloci*)
			p=oci
			;;

		apps/qt5/qml/*)
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
		apps/qt5/translations/assistant_*|\
		apps/qt5/translations/linguist_*|\
		apps/qt5/translations/designer_*)
			p=tools
			;;

		apps/qt5/translations/qt_*|\
		apps/qt5/translations/qtbase_*|\
		apps/qt5/translations/qtconnectivity_*|\
		apps/qt5/translations/qtdeclarative_*|\
		apps/qt5/translations/qtlocation_*|\
		apps/qt5/translations/qtmultimedia_*|\
		apps/qt5/translations/qtserialport_*|\
		apps/qt5/translations/qtscript_*|\
		apps/qt5/translations/qtwebsockets_*|\
		apps/qt5/translations/qtxmlpatterns_*|\
		apps/qt5/translations/qtwebengine_*)
			p=libs
			;;

		apps/qt5/translations/qtquickcontrols*)
			p=qml
			;;

		*)
			echo "Unknown qm: $f" | tee -a /tmp/qt.unknown
			continue
			;;

		esac
		;;

        *)
		case "$f" in
		apps/qt5/doc/*)
			p=docs
			;;

		apps/qt5/include/*|\
		apps/qt5/lib/cmake/*|\
		apps/qt5/mkspecs/*|\
		apps/qt5/phrasebooks/*)
			p=devel
			;;

		apps/qt5/qml/*)
			p=qml
			;;

		apps/qt5/resources/icudtl.dat|\
		apps/qt5/resources/qtwebengine*|\
		apps/qt5/translations/qtwebengine_locales/*)
			p=libs
			;;

		apps/qt5/lib/metatypes/*_metatypes.json)
			;;

		*)
			echo "Unknown extension $e: $f" | tee -a /tmp/qt.unknown
			continue
			;;
		esac

        esac

        echo $f >>/tmp/$p
done </tmp/qt.files

set -x

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-{devel,qml,tools,docs,libs,libs-symbols,oci}

#
# libs (files + ini bat + qt.conf)
#

cat <<EOF >../qt5.bat
path %OSGEO4W_ROOT%\\apps\\qt5\\bin;%PATH%

set QT_PLUGIN_PATH=%OSGEO4W_ROOT%\\apps\\Qt5\\plugins

set O4W_QT_PREFIX=%OSGEO4W_ROOT:\\=/%/apps/Qt5
set O4W_QT_BINARIES=%OSGEO4W_ROOT:\\=/%/apps/Qt5/bin
set O4W_QT_PLUGINS=%OSGEO4W_ROOT:\\=/%/apps/Qt5/plugins
set O4W_QT_LIBRARIES=%OSGEO4W_ROOT:\\=/%/apps/Qt5/lib
set O4W_QT_TRANSLATIONS=%OSGEO4W_ROOT:\\=/%/apps/Qt5/translations
set O4W_QT_HEADERS=%OSGEO4W_ROOT:\\=/%/apps/Qt5/include
set O4W_QT_DOC=%OSGEO4W_ROOT:\\=/%/apps/Qt5/doc
EOF

cat <<EOF >../qt5.conf
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
sdesc: "Qt5 runtime libraries"
ldesc: "Qt5 runtime libraries"
maintainer: $MAINTAINER
category: Libs
requires: base msvcrt2019 openssl sqlite3 zlib libjpeg-turbo libtiff libpng libwebp libmysql zstd libpq icu freetype
external-source: $P
EOF

tar -cjf $R/$P-libs/$P-libs-$V-$B.tar.bz2 \
	--absolute-names \
	--xform s,^../qt5.bat,etc/ini/qt5.bat, \
	--xform s,^../qt5.conf,bin/qt.conf, \
	--xform s,^.././qt5.conf,apps/qt5/bin/qt.conf, \
	../qt5.bat \
	../qt5.conf \
	.././qt5.conf \
	-T /tmp/libs

#
# libs-symbols
#

cat <<EOF >../qt5.sha
[Git]
SHA=$SHA
Url=$GITREPO
EOF

cat <<EOF >$R/$P-libs-symbols/setup.hint
sdesc: "Qt5 runtime libraries (release version; symbol files)"
ldesc: "Qt5 runtime libraries (release version; symbol files)"
maintainer: $MAINTAINER
category: Libs
requires: $P-libs
external-source: $P
EOF

tar -cjf $R/$P-libs-symbols/$P-libs-symbols-$V-$B.tar.bz2 \
	--absolute-names \
	--xform s,^../qt5.sha,apps/qt5/qt5.sha, \
	../qt5.sha \
	-T /tmp/symbols

#
# oci
#

cat <<EOF >$R/$P-oci/setup.hint
sdesc: "Qt5 OCI SQL plugin"
ldesc: "Qt5 OCI SQL plugin"
maintainer: $MAINTAINER
category: Libs
requires: $P-libs oci
external-source: $P
EOF

tar -cjf $R/$P-oci/$P-oci-$V-$B.tar.bz2 \
	-T /tmp/oci


#
# tools
#

cat <<EOF >$R/$P-tools/setup.hint
sdesc: "Qt5 tools (Development)"
ldesc: "Qt5 tools (Development)"
maintainer: $MAINTAINER
category: Desktop Commandline_Utilities
requires: $P-libs
external-source: $P
EOF

tar -cjf $R/$P-tools/$P-tools-$V-$B.tar.bz2 \
	-T /tmp/tools

#
# devel
#

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "Qt5 headers and libraries (Development)"
ldesc: "Qt5 headers and libraries (Development)"
maintainer: $MAINTAINER
category: Libs
requires: $P-libs
external-source: $P
EOF

tar -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	-T /tmp/devel

#
# documentation (TODO; requires sphinx for Python2?)
#

cat <<EOF >$R/$P-docs/setup.hint
sdesc: "Qt5 documentation (Development)"
ldesc: "Qt5 documentation (Development)"
maintainer: $MAINTAINER
category: Libs
requires: 
external-source: $P
EOF

tar -cjf $R/$P-docs/$P-docs-$V-$B.tar.bz2 \
	-T /tmp/docs

#
# QtQuick / QML
#

cat <<EOF >$R/$P-qml/setup.hint
sdesc: "Qt5 QML"
ldesc: "Qt5 QML"
maintainer: $MAINTAINER
category: Libs
requires: $P-libs
external-source: $P
EOF

tar -cjf $R/$P-qml/$P-qml-$V-$B.tar.bz2 \
	-T /tmp/qml

#
# source
#

tar -cjf $R/$P-$V-$B-src.tar.bz2 \
	-C ../.. \
	osgeo4w/package.sh

#
# license
#

for i in devel qml tools docs libs libs-symbols oci; do
	cp ../../$P/LICENSE.GPLv3 $R/$P-$i/$P-$i-$V-$B.txt
done

#
# check
#

for i in devel qml tools docs libs libs-symbols oci; do
	tar -tjf $R/$P-$i/$P-$i-$V-$B.tar.bz2
done >/tmp/qt.installed

sort /tmp/qt.installed | uniq -d >/tmp/qt.dupes || true
if [ -s /tmp/qt.dupes ]; then
	echo Duplicate packaged files:
	cat /tmp/qt.dupes
fi

sort /tmp/qt.files /tmp/qt.installed | uniq -u | fgrep -v -x -f <(cat <<EOF
bin/qt.conf
apps/qt5/bin/qt.conf
etc/ini/qt5.bat
apps/qt5/qt5.sha
EOF
) >/tmp/qt.not-installed || true

if [ -s /tmp/qt.not-installed ]; then
	echo Not packaged files:
	cat /tmp/qt.not-installed
fi

! [ -s /tmp/qt.dupes ] && ! [ -s /tmp/qt.not-installed ]

endlog
