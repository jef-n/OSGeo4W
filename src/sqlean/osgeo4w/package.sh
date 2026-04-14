export P=sqlean
export V=0.28.2
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=sqlite3-devel
export PACKAGES=sqlean

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget -O $P-$V.tar.gz https://github.com/nalgeon/$P/archive/refs/tags/$V.tar.gz
[ -f ../$P-$V/Makefile ] || tar -C .. -xzf $P-$V.tar.gz
[ -s ../$P-$V/src/crypto/xxhash.impl.h ] || wget -O ../$P-$V/src/crypto/xxhash.impl.h https://raw.githubusercontent.com/Cyan4973/xxHash/refs/tags/v0.8.3/xxhash.h
[ -s ../$P-$V/src/test_windirent.h ] || wget -O ../$P-$V/src/test_windirent.h https://raw.githubusercontent.com/mackyle/sqlite/branch-3.36/src/test_windirent.h

find ../$P-$V -name extension.c | while read f; do
	d=${f%/*}
	d=${d##*/}
	mv "$f" "${f%/extension.c}/${d}_extension.c"
done

[ -f ../$P-$V/patched ] || {
	patch -p1 -d ../$P-$V --dry-run <patch
	patch -p1 -d ../$P-$V <patch >../$P-$V/patched
}

(
	vsenv

	export INCLUDE="$(cygpath -aw osgeo4w/include);$(cygpath -aw ../$P-$V);$(cygpath -aw ../$P-$V/src);$INCLUDE"

	make -C ../$P-$V -f ../osgeo4w/Makefile
)

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R

cat <<EOF >$R/setup.hint
sdesc: "All the missing SQLite functions"
ldesc: "All the missing SQLite functions"
category: Libs
requires: msvcrt2019 sqlite3
maintainer: $MAINTAINER
EOF

tar -cjf $R/$P-$V-$B.tar.bz2 \
	--xform "s,$P-$V/$P.dll,bin/$P.dll," \
	--xform "s,$P-$V/,apps/sqlean/," \
	../$P-$V/*.dll

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 \
	osgeo4w/package.sh \
	osgeo4w/Makefile \
	osgeo4w/patch

cp ../$P-$V/LICENSE $R/$P-$V-$B.txt

endlog
