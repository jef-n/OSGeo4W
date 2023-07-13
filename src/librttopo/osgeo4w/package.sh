export P=librttopo
export V=1.1.0
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=geos-devel

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget https://git.osgeo.org/gitea/rttopo/librttopo/archive/$P-$V.tar.gz
[ -f ../$P/makefile.vc ] || tar -C .. -xzf  $P-$V.tar.gz
[ -f ../$P/src/rttopo_config.h ] || wget -O ../$P/src/rttopo_config.h https://git.osgeo.org/gitea/attachments/d6ae54b6-109d-480e-bd7c-020d2a543cd6
[ -f ../$P/headers/librttopo_geom.h ] || wget -O ../$P/headers/librttopo_geom.h https://git.osgeo.org/gitea/attachments/b4e500d5-6168-4022-91c5-b7de6346167e

vs2019env

mkdir -p install

# Fixup makefile
if ! [ -f ../$P/fixed ]; then
	src=$(cd ../$P; ls -1 src/*.c | sed -e 's/\.c/.obj/g' | paste -d' ' -s | fold -s | sed -e 's/$/\\\\\\n\\t/' | paste -d' ' -s)
	src=${src%\\}

	sed -r -i \
		-e 's/C:\\OSGeo4W/$(OSGEO4W_ROOT)/g' \
		-e "/LIBOBJ\s*=/,/^$/ c LIBOBJ = $src" \
		../$P/makefile.vc

	sed -i -e '/INSTDIR=/d' ../$P/nmake.opt
	
	touch ../$P/fixed
fi

cd ../$P

nmake /f makefile.vc OSGEO4W_ROOT=$(cygpath -aw ../osgeo4w/osgeo4w)
nmake /f makefile.vc OSGEO4W_ROOT=$(cygpath -aw ../osgeo4w/osgeo4w) INSTDIR=..\\osgeo4w\\install install

cd ../osgeo4w

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "RT Topology Library (Runtime)"
ldesc: "RT Topology Library (Runtime)"
category: Libs
requires: msvcrt2019 geos
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 bin

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "RT Topology Library (Development)"
ldesc: "RT Topology Library (Development)"
category: Libs
requires: $P
maintainer: $MAINTAINER
external-source: $P
EOF

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 include lib

cp ../$P/COPYING $R/$P-$V-$B.txt
cp ../$P/COPYING $R/$P-devel/$P-devel-$P-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh osgeo4w/makefile.o4w

endlog
