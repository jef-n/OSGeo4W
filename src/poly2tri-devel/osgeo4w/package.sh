export P=poly2tri-devel
export V=tbd
export B=tbd
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none
export PACKAGES=poly2tri-devel

source ../../../scripts/build-helpers

startlog

V=$(date +%Y%m%d)
B=1

if [ -d ../poly2tri ]; then
	(
		cd ../poly2tri
		git pull
	)
else
	(
		cd ..
		git clone https://github.com/jhasse/poly2tri.git
	)
fi

vsenv
cmakeenv
ninjaenv

mkdir -p build install

cd build

cmake -G Ninja \
	-D CMAKE_BUILD_TYPE=Release \
	../../poly2tri
ninja

cd ..

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R

cat <<EOF >$R/setup.hint
sdesc: "poly2tri (development)"
ldesc: "poly2tri (development)"
maintainer: JuergenFischer
category: Libs
requires: msvcrt2019
EOF

tar -C .. -cjf $R/$P-$V-$B.tar.bz2 \
	--xform s,osgeo4w/build/poly2tri.lib,lib/poly2tri.lib, \
	--xform s,poly2tri/poly2tri/,include/poly2tri/, \
	poly2tri/poly2tri/ \
	osgeo4w/build/poly2tri.lib

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

cp ../poly2tri/LICENSE $R/$P-$V-$B.txt

endlog
