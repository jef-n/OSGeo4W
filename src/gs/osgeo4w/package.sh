export P=gs
export V=10.02.1
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none

source ../../../scripts/build-helpers

startlog

[ -f gs${V//./}w64.exe ] || wget https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/$P${V//./}/$P${V//./}w64.exe

[ -d install ] || {
	mkdir -p install

	cd install
	7z -y x ../$P${V//./}w64.exe
	cd ..
}

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P

cat <<EOF >$R/setup.hint
sdesc: "Ghostscript is an interpreter for the PostScript® language and PDF files."
ldesc: "Ghostscript is an interpreter for the PostScript® language and PDF files.
Repackaged binaries from ghostscript.com
"
category: Libs
requires: msvcrt2019
maintainer: $MAINTAINER
EOF

mkdir -p install/etc/ini

cat <<EOF >install/etc/ini/gs.bat
set GS_LIB=%OSGEO4W_ROOT%\\apps\\gs\\lib
EOF

cp install/bin/gswin64c.exe install/bin/gswin32c.exe
cp install/bin/gswin64c.exe install/bin/gs.exe

tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	--xform "s,^Resource,apps/gs/Resource," \
	--xform "s,^lib,apps/gs/lib," \
	--xform "s,^doc,apps/gs/doc," \
	--xform "s,^iccprofiles,apps/gs/iccprofiles," \
	Resource \
	lib \
	bin/gsdll64.dll \
	bin/gswin32c.exe \
	bin/gswin64c.exe \
	bin/gs.exe \
	etc/ini/gs.bat

cp install/doc/COPYING $R/$P-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
