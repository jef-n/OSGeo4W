export P=qscintilla-qt6
export V=2.14.1
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="qt6-devel python3-devel python3-setuptools python3-pip python3-pyqt6 python3-pyqt-builder python3-pyqt6-sip"
export PACKAGES="python3-pyqt6-qscintilla qscintilla-qt6 qscintilla-qt6-devel"

source ../../../scripts/build-helpers

startlog

export qsc=QScintilla_src-$V
export pp=python3-pyqt6-qscintilla

[ -f $qsc.tar.gz ] || wget https://www.riverbankcomputing.com/static/Downloads/QScintilla/$V/$qsc.tar.gz
[ -d ../$qsc/src ] || tar -C .. -xzf $qsc.tar.gz
[ -d ../$qsc/src ]

(
	fetchenv osgeo4w/bin/o4w_env.bat
	fetchenv osgeo4w/bin/qt6_env.bat
	vsenv

	export LIB="$LIB;$(cygpath -am osgeo4w/lib)"
	export INCLUDE="$INCLUDE;$(cygpath -am osgeo4w/include)"

	cd ../$qsc/src
	qmake qscintilla.pro

	[ -z "$OSGEO4W_SKIP_CLEAN" ] || nmake /f Makefile.Release clean
	nmake /f Makefile.Release install

	cd ../Python
	cp pyproject-qt6.toml pyproject.toml
	pip3 install .
	P=$pp packagewheel
)

export R=$OSGEO4W_REP/x86_64/release/qt6/$P
mkdir -p $R/{$P-devel,$pp}

mv osgeo4w/apps/Qt6/lib/qscintilla2_qt6.dll osgeo4w/apps/Qt6/bin/qscintilla2_qt6.dll
cp osgeo4w/apps/Qt6/lib/qscintilla2_qt6.lib osgeo4w/apps/Qt6/lib/qscintilla2.lib

cp ../$qsc/LICENSE $R/$P-$V-$B.txt
cp ../$qsc/LICENSE $R/$P-devel/$P-devel-$V-$B.txt
cp ../$qsc/LICENSE $R/$pp/$pp-$V-$B.txt

cat <<EOF >$R/setup.hint
sdesc: "Qt6 source code editing component."
ldesc: "Qt6 source code editing component."
maintainer: $MAINTAINER
category: Libs
requires: qt6-libs
EOF

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "Qt6 source code editing component. (Development)"
ldesc: "Qt6 source code editing component. (Development)"
maintainer: $MAINTAINER
category: Libs
requires: $P
external-source: $P
EOF

cat <<EOF >$R/$pp/setup.hint
sdesc: "Python3 bindings for Qt6 QScintilla"
ldesc: "Python3 bindings for Qt6 QScintilla"
maintainer: $MAINTAINER
category: Libs
requires: python3-core python3-sip python3-pyqt6 $P
external-source: $P
EOF

cd osgeo4w

tar -cjvf $R/$P-$V-$B.tar.bz2 \
	apps/Qt6/bin/qscintilla2*.dll

tar -cjvf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	apps/Qt6/include/Qsci \
	apps/Qt6/qsci/api/python \
	apps/Qt6/translations/qscintilla_*.qm \
	apps/Qt6/lib/qscintilla2*.lib

tar -cjvf $R/$pp/$pp-$V-$B.tar.bz2 \
	apps/$PYTHON/Lib/site-packages/PyQt6/Qsci.pyd \
	apps/$PYTHON/Lib/site-packages/PyQt6/bindings/Qsci/

cd ..

tar -C .. -cjvf $R/$P-$V-$B-src.tar.bz2 \
	osgeo4w/package.sh

endlog
