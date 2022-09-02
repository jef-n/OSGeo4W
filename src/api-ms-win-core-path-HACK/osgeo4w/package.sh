export P=api-ms-win-core-path-HACK
export V=0.0.1
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none

source ../../../scripts/build-helpers

startlog

cd ..

[ -d $P ] || git clone https://github.com/nalexandru/$P.git
cd $P

(
	set -e

	vs2019env

	set -x
	devenv api-ms-win-core-path-blender.sln /Build "Release|x64"
)

cd ../osgeo4w

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R

cat <<EOF >$R/setup.hint
sdesc: "Hack to make python 3.9 work on Windows 7"
ldesc: "This is an implementation of api-ms-win-core-path-l1-1-0.dll based on
Wine code. Originally  made to run Blender 2.93 (specifically, Python 3.9) on Windows
7."
maintainer: $MAINTAINER
category: Libraries
requires: msvcrt2019
EOF

tar -C ../$P/build/x64/release -cjf $R/$P-$V-$B.tar.bz2 \
	--xform s,api-ms-win-core-path-l1-1-0.dll,bin/api-ms-win-core-path-l1-1-0.dll, \
	api-ms-win-core-path-l1-1-0.dll

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 \
	osgeo4w/package.sh

endlog
