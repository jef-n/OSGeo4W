export P=qscintilla
export V=2.11.5
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="qt5-devel python3-setuptools python3-pyqt5 python3-sip python3-pyqt5-sip"

source ../../../scripts/build-helpers

startlog

[ -f QScintilla-$V.tar.gz ] || wget https://www.riverbankcomputing.com/static/Downloads/QScintilla/$V/QScintilla-$V.tar.gz
[ -d ../Qt4Qt5 ] || tar -C .. -xzf QScintilla-$V.tar.gz --xform s,QScintilla-$V,.,

(
	fetchenv osgeo4w/bin/o4w_env.bat
	vs2019env

	export LIB="$LIB;$(cygpath -am osgeo4w/lib)"
	export INCLUDE="$INCLUDE;$(cygpath -am osgeo4w/include)"

	cd ../Qt4Qt5
	qmake qscintilla.pro

	nmake /f Makefile.Release clean
	nmake /f Makefile.Release
	nmake /f Makefile.Release install

	cd ../Python
	python configure.py --verbose --pyqt=PyQt5 \

	nmake clean
	nmake
	nmake install
)

export R=$OSGEO4W_REP/x86_64/release/qt5/$P
mkdir -p $R/{$P-devel,python3-$P}

mv osgeo4w/apps/Qt5/lib/qscintilla2_qt5.dll osgeo4w/apps/Qt5/bin/qscintilla2_qt5.dll
cp osgeo4w/apps/Qt5/lib/qscintilla2_qt5.lib osgeo4w/apps/Qt5/lib/qscintilla2.lib

cp ../LICENSE $R/$P-$V-$B.txt
cp ../LICENSE $R/$P-devel/$P-devel-$V-$B.txt
cp ../LICENSE $R/python3-$P/python3-$P-$V-$B.txt

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
external-source: qt5/$P
EOF

cat <<EOF >$R/python3-$P/setup.hint
sdesc: "Python3 bindings for Qt5 QScintilla"
ldesc: "Python3 bindings for Qt5 QScintilla"
maintainer: $MAINTAINER
category: Libs
requires: python3-core python3-sip python3-pyqt5 $P
external-source: qt5/$P
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
