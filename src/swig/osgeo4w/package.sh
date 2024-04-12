export P=swig
export V=4.2.1
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none
export PACKAGES="swig"

source ../../../scripts/build-helpers

startlog

[ -f swigwin-4.0.2.zip ] || wget http://prdownloads.sourceforge.net/swig/swigwin-$V.zip
[ -f ../swigwin-$V/swig.exe ] || unzip -d .. swigwin-$V.zip

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R

cat <<EOF >swig.bat
@"%OSGEO4W_ROOT%\\apps\\swigwin\\swig.exe" %*
EOF

tar -cjf $R/$P-$V-$B.tar.bz2 \
	--exclude "../swigwin-$V/Examples" \
	--exclude "../swigwin-$V/Source" \
	--exclude "../swigwin-$V/Tools" \
	--exclude "../swigwin-$V/CCache" \
	--xform "s,swigwin-$V,apps/swigwin," \
	--xform "s,swig.bat,bin/swig.bat," \
	../swigwin-$V \
	swig.bat

cat <<EOF >$R/setup.hint
sdesc: "SWIG is a tool to build language bindings."
ldesc: "SWIG is a tool to build language bindings.
Repackaged binary from swig.org
"
category: Commandline_Utilities
requires: 
EOF

cp ../swigwin-$V/LICENSE $R/$P-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
