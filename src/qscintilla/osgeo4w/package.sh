export P=qscintilla
export V=2.13.1
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="qt5-devel python3-setuptools python3-pyqt5 python3-pyqt-builder"

source ../../../scripts/build-helpers

startlog

export qsc=QScintilla_src-$V

[ -f $qsc.tar.gz ] || wget https://www.riverbankcomputing.com/static/Downloads/QScintilla/$V/$qsc.tar.gz
[ -d ../$qsc/src ] || tar -C .. -xzf $qsc.tar.gz
[ -d ../$qsc/src ]

(
	fetchenv osgeo4w/bin/o4w_env.bat
	vs2019env

	export LIB="$LIB;$(cygpath -am osgeo4w/lib)"
	export INCLUDE="$INCLUDE;$(cygpath -am osgeo4w/include)"

	cd ../$qsc/src
	qmake qscintilla.pro

	[ -z "$OSGEO4W_SKIP_CLEAN" ] || nmake /f Makefile.Release clean
	nmake /f Makefile.Release install

	cd ../Python
	cp pyproject-qt5.toml pyproject.toml
	sip-install
)

export R=$OSGEO4W_REP/x86_64/release/qt5/$P
mkdir -p $R/{$P-devel,python3-$P}

mv osgeo4w/apps/Qt5/lib/qscintilla2_qt5.dll osgeo4w/apps/Qt5/bin/qscintilla2_qt5.dll
cp osgeo4w/apps/Qt5/lib/qscintilla2_qt5.lib osgeo4w/apps/Qt5/lib/qscintilla2.lib

cp ../$qsc/LICENSE $R/$P-$V-$B.txt
cp ../$qsc/LICENSE $R/$P-devel/$P-devel-$V-$B.txt
cp ../$qsc/LICENSE $R/python3-$P/python3-$P-$V-$B.txt

cat <<EOF >$R/setup.hint
sdesc: "Qt5 source code editing component."
ldesc: "Qt5 source code editing component."
maintainer: $MAINTAINER
category: Libs
requires: qt5-libs
EOF

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "Qt5 source code editing component. (Development)"
ldesc: "Qt5 source code editing component. (Development)"
maintainer: $MAINTAINER
category: Libs
requires: $P
external-source: $P
EOF

cat <<EOF >$R/python3-$P/setup.hint
sdesc: "Python3 bindings for Qt5 QScintilla"
ldesc: "Python3 bindings for Qt5 QScintilla"
maintainer: $MAINTAINER
category: Libs
requires: python3-core python3-sip python3-pyqt5 $P
external-source: $P
EOF

cd osgeo4w

tar -cjvf $R/$P-$V-$B.tar.bz2 \
	apps/Qt5/bin/qscintilla2*.dll

tar -cjvf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	apps/Qt5/include/Qsci \
	apps/Qt5/qsci/api/python \
	apps/Qt5/translations/qscintilla_*.qm \
	apps/Qt5/lib/qscintilla2*.lib

tar -cjvf $R/python3-$P/python3-$P-$V-$B.tar.bz2 \
	apps/$PYTHON/Lib/site-packages/PyQt5/Qsci.pyd \
	apps/$PYTHON/Lib/site-packages/PyQt5/bindings/Qsci/

cd ..

tar -C .. -cjvf $R/$P-$V-$B-src.tar.bz2 \
	osgeo4w/package.sh

endlog
