export P=icu
export V=67.1
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none

source ../../../scripts/build-helpers

startlog

[ -f ${P}4c-${V/./_}-src.tgz ] || wget -q https://github.com/unicode-org/icu/releases/download/release-${V/./-}/${P}4c-${V/./_}-src.tgz
[ -d ../source ] || tar -C .. -xzf  ${P}4c-${V/./_}-src.tgz --xform "s,^icu,.,"
[ -f patched ] || {
	patch -d .. -p1 --dry-run <patch
	patch -d .. -p1 <patch
	touch patched
}

vs2019env

# Make sure /bin is in front of system32 (so we don't use Windows' bash in pkgdata)
PATH=$(
	echo $PATH |
	sed -e "s/:/\n/g" |
	(
		fgrep -i -v -x -f <(
			cygpath --sysdir
			cygpath --windir
		)
		echo /bin
		cygpath --sysdir
		cygpath --windir
	) |
	tr [:upper:] [:lower:] |
	awk '!x[$0]++' |
        paste -s -d":"
)

mkdir -p install

cd ../source

[ -f Makefile ] || ./runConfigureICU Cygwin/MSVC --prefix=$(cygpath -a ../osgeo4w/install)
mkdir -p data/out/tmp  # fails otherwise
make
[ -f $OSGEO4W_PWD/nocheck ] || make check
make install

cd ../osgeo4w/install

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-{devel,tools}

cat <<EOF >$R/setup.hint
sdesc: "Libraries providing Unicode and Globalization support for software applications (runtime)"
ldesc: "ICU is a mature, widely used set of C/C++ and Java libraries providing
Unicode and Globalization support for software applications. ICU is widely
portable and gives applications the same results on all platforms and between
C/C++ and Java software."
category: Libs
requires: msvcrt2019
maintainer: $MAINTAINER
EOF

tar -cjf $R/$P-$V-$B.tar.bz2 \
	--xform "s,^lib,bin," \
	lib/*.dll

cat <<EOF >$R/$P-tools/setup.hint
sdesc: "Libraries providing Unicode and Globalization support for software applications (tools)"
ldesc: "ICU is a mature, widely used set of C/C++ and Java libraries providing
Unicode and Globalization support for software applications. ICU is widely
portable and gives applications the same results on all platforms and between
C/C++ and Java software."
category: Libs
requires: $P
maintainer: $MAINTAINER
external-source: $P
EOF

tar -cjf $R/$P-tools/$P-tools-$V-$B.tar.bz2 \
	bin \
	share/man

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "Libraries providing Unicode and Globalization support for software applications (development)"
ldesc: "ICU is a mature, widely used set of C/C++ and Java libraries providing
Unicode and Globalization support for software applications. ICU is widely
portable and gives applications the same results on all platforms and between
C/C++ and Java software."
category: Libs
requires: $P
maintainer: $MAINTAINER
external-source: $P
EOF

tar -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	--exclude "*.dll" \
	lib \
	include \
	share/icu

cd ..

cp ../LICENSE $R/$P-$V-$B.txt
cp ../LICENSE $R/$P-devel/$P-devel-$P-$V-$B.txt
cp ../LICENSE $R/$P-tools/$P-tools-$P-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh osgeo4w/patch

endlog
