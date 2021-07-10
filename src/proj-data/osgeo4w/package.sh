export P=proj-data
export V=1.7
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none

source ../../../scripts/build-helpers

startlog

[ -f proj-data-$V.tar.gz ] || wget -c http://ftp.osuosl.org/pub/osgeo/download/proj/proj-data-$V.tar.gz

mkdir -p share/proj
tar -C share/proj -xzf proj-data-$V.tar.gz

export R=$OSGEO4W_REP/x86_64/release/proj/$P
mkdir -p $R

cat <<EOF >$R/setup.hint
sdesc: "The PROJ data"
ldesc: "The PROJ data"
category: Libs
requires:
maintainer: $MAINTAINER
EOF

tar --remove-files -cjf $R/$P-$V-$B.tar.bz2 share
tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
