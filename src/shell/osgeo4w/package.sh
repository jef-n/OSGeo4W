export P=shell
export V=99.0.0
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none
export PACKAGES="shell"

source ../../../scripts/build-helpers

startlog

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R

cat <<EOF >$R/setup.hint
sdesc: "UPGRADES FROM OLD OSGEO4W NOT SUPPORTED"
ldesc: "OSGeo4W transitional package

UPGRADES FROM OLD OSGEO4W NOT SUPPORTED"
maintainer: $MAINTAINER
category: Commandline_Utilities
requires:
EOF


cat <<EOF >postinstall.bat
msg "*" UPGRADES FROM OLD OSGEO4W NOT SUPPORTED - PLEASE DO A FRESH INSTALL
echo UPGRADES FROM OLD OSGEO4W NOT SUPPORTED - PLEASE DO A FRESH INSTALL
exit /b 1
EOF

tar -cjf $R/$P-$V-$B.tar.bz2 \
	--xform "s,^postinstall.bat,etc/postinstall/$P.bat," \
	postinstall.bat

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 \
	osgeo4w/package.sh

endlog
