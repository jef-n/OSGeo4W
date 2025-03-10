export P=mod_fcgid
export V=2.3.10
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none
export PACKAGES="mod_fcgid"

source ../../../scripts/build-helpers

startlog

[ -f "$P-$V-win64-VC17.zip" ] || curl -LO https://www.apachelounge.com/download/VS17/modules/$P-$V-win64-VS17.zip
unzip -o $P-$V-win64-VS17.zip $P-$V/LICENSE-FCGID $P.so

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R

cat <<EOF >$R/setup.hint
sdesc: "Apache FastCGI ASF module"
ldesc: "Apache FastCGI ASF module (apachelounge binaries)"
maintainer: $MAINTAINER
category: Web
requires: apache
EOF

cp $P-$V/LICENSE-FCGID $R/$P-$V-$B.txt

tar -cjf $R/$P-$V-$B.tar.bz2 \
	--xform s,^,apps/apache/modules/, \
	$P.so

tar -cjf $R/$P-$V-$B-src.tar.bz2 \
	-C .. \
	osgeo4w/package.sh

rm -r $P-$V $P.so

endlog
