export P=swig
export V=4.0.2
export B=next
export MAINTAINER=JuergenFischer

source ../../../scripts/build-helpers

startlog

[ -f swigwin-4.0.2.zip ] || wget http://prdownloads.sourceforge.net/swig/swigwin-$V.tar.gz
[ -f ../swigwin-$V/swig.exe ] || unzip -d .. swigwin-$V.zip swigwin-$V/LICENSE swigwin-$V/swig.exe

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R

tar -C ../swigwin-$V -cjf $R/$P-$V-$B.tar.bz2 \
	--xform "s,swig.exe,bin/swig.exe," \
	swig.exe

cat <<EOF >$R/setup.hint
sdesc: "SWIG is a tool for build language bindings."
ldesc: "SWIG is a tool for build language bindings.
Repackaged binary from swig.org
"
category: Commandline_Utilities
requires: 
EOF

cp ../swigwin-$V/LICENSE $R/$P-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
