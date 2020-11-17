export P=qwt
export V=6.1.3
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=qt5-devel

source ../../../scripts/build-helpers

startlog

set -e

[ -f qwt-$V.tar.bz2 ] || wget https://deac-riga.dl.sourceforge.net/project/$P/$P/$V/$P-$V.tar.bz2
[ -f ../qwtbuild.pri ] || tar -C .. -xjf $P-$V.tar.bz2 --xform "s,$P-$V,.,"
[ -f patched ] || {
	patch -d .. -p1 --dry-run <diff
	patch -d .. -p1 <diff
	touch patched
}

(
	fetchenv osgeo4w/bin/o4w_env.bat
	vs2019env

	cd ..

	[ -f Makefile ] && nmake distclean
	qmake qwt.pro
	nmake clean
	nmake
	nmake install
)

export R=$OSGEO4W_REP/x86_64/release/qt5/$P

for i in doc libs devel; do
	mkdir -p $R/$P-$i
	cp ../COPYING $R/$P-$i/$P-$i-$V-$B.txt
done

cat <<EOF >$R/$P-doc/setup.hint
sdesc: "Qt5 widgets library for technical applications (Documentation)"
ldesc: "Qt5 widgets library for technical applications (Documentation)"
maintainer: $MAINTAINER
category: Libs
requires:
external-source: $P
EOF

cat <<EOF >$R/$P-libs/setup.hint
sdesc: "Qt5 widgets library for technical applications (Runtime)"
ldesc: "Qt5 widgets library for technical applications (Runtime)"
maintainer: $MAINTAINER
category: Libs
requires: $P-libs
external-source: $P
EOF

		cat <<EOF >$R/$P-devel/setup.hint
sdesc: "Qt5 widgets library for technical applications (Development)"
ldesc: "Qt5 widgets library for technical applications (Development)"
maintainer: $MAINTAINER
category: Libs
requires: $P-libs
external-source: $P
EOF

tar -C install -cjvf $R/$P-doc/$P-doc-$V-$B.tar.bz2 \
	apps/qwt6/doc

tar -C install -cjvf $R/$P-libs/$P-libs-$V-$B.tar.bz2 \
	--xform s,apps/Qt5/lib/qwt.dll,apps/Qt5/bin/qwt.dll, \
	apps/Qt5/lib/qwt.dll

tar -C install -cjvf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	--absolute-names \
	--xform s,../../lib/qwt.lib,apps/Qt5/lib/qwt.lib, \
	apps/Qt5/features \
	apps/Qt5/include/qwt6 \
	../../lib/qwt.lib \
	apps/Qt5/plugins/designer/qwt_designer_plugin.dll

tar -C .. -cjvf $R/$P-$V-$B-src.tar.bz2 \
	osgeo4w/package.sh osgeo4w/diff

endlog
