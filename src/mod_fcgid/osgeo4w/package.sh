export P=mod_fcgid
export V=2.3.10
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none

source ../../../scripts/build-helpers

startlog

[ -f "$P-$V-win64-VC16.zip" ] || curl -L -A Mozilla/5.0 -O https://www.apachelounge.com/download/VS16/modules/$P-$V-win64-VS16.zip
[ -d $P-$V ] || unzip -o $P-$V-win64-VS16.zip $P-$V/LICENSE-FCGID $P-$V/$P.so

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
	--xform s,^$P-$V/,apps/apache/modules/, \
	$P-$V/$P.so

tar -cjf $R/$P-$V-$B-src.tar.bz2 \
	-C .. \
	osgeo4w/package.sh

endlog
