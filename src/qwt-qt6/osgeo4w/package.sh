export P=qwt-qt6
export V=6.3.0
export B="next qwt-libs"
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=qt6-devel
export PACKAGES="qwt-qt6-devel qwt-qt6-doc qwt-qt6-libs"

source ../../../scripts/build-helpers

startlog

set -e

p=${P%-qt6}
[ -f $p-$V.tar.bz2 ] || wget https://deac-ams.dl.sourceforge.net/project/$p/$p/$V/$p-$V.tar.bz2
[ -f ../$p-$V/qwtbuild.pri ] || tar -C .. -xjf $p-$V.tar.bz2
[ -f ../$p-$V/patched ] || {
	patch -d ../$p-$V -p1 --dry-run <diff
	patch -d ../$p-$V -p1 <diff >../$p-$V/patched
}

(
	fetchenv osgeo4w/bin/o4w_env.bat
	fetchenv osgeo4w/bin/qt6_env.bat
	vsenv

	mkdir -p install

	cd ../$p-$V

	[ -f Makefile ] && nmake distclean
	qmake CONFIG-=debug_and_release CONFIG-=debug CONFIG+=release CONFIG+=force_with_debug CONFIG-=examples qwt.pro
	nmake clean
	nmake
	nmake install
)

export R=$OSGEO4W_REP/x86_64/release/qt6/$P

for i in doc libs devel; do
	mkdir -p $R/$P-$i
	cp ../$p-$V/COPYING $R/$P-$i/$P-$i-$V-$B.txt
done

cat <<EOF >$R/$P-doc/setup.hint
sdesc: "Qt6 widgets library for technical applications (Documentation)"
ldesc: "Qt6 widgets library for technical applications (Documentation)"
maintainer: $MAINTAINER
category: Libs
requires:
external-source: $P
EOF

cat <<EOF >$R/$P-libs/setup.hint
sdesc: "Qt6 widgets library for technical applications (Runtime)"
ldesc: "Qt6 widgets library for technical applications (Runtime)"
maintainer: $MAINTAINER
category: Libs
requires: $P-libs qt6-libs
external-source: $P
EOF

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "Qt6 widgets library for technical applications (Development)"
ldesc: "Qt6 widgets library for technical applications (Development)"
maintainer: $MAINTAINER
category: Libs
requires: $P-libs
external-source: $P
EOF

tar -C install -cjvf $R/$P-doc/$P-doc-$V-$B.tar.bz2 \
	apps/$P/doc

tar -C install -cjvf $R/$P-libs/$P-libs-$V-$B.tar.bz2 \
	--xform s,apps/Qt6/lib/qwt.dll,apps/Qt6/bin/qwt.dll, \
	apps/Qt6/lib/qwt.dll

tar -C install -cjvf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	--absolute-names \
	--xform s,./apps/Qt6/lib/qwt.lib,apps/Qt6/lib/qwt-qt6.lib, \
	apps/Qt6/features \
	apps/Qt6/include/qwt6 \
	apps/Qt6/lib/qwt.lib \
	./apps/Qt6/lib/qwt.lib \
	apps/Qt6/plugins/designer/qwt_designer_plugin.dll

tar -C .. -cjvf $R/$P-$V-$B-src.tar.bz2 \
	osgeo4w/package.sh osgeo4w/diff

endlog
