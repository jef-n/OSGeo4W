export P=ogdi
export V=4.1.0
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="expat-devel zlib-devel"

source ../../../scripts/build-helpers

startlog

[ -f ogdi_${V//./_}.tar.gz ] || wget https://github.com/libogdi/ogdi/archive/ogdi_${V//./_}.tar.gz
if ! [ -f ../makefile ]; then
	tar -C .. -xzf ogdi_${V//./_}.tar.gz --xform s,ogdi-ogdi_${V//./_},.,
	patch -d .. -p0 <diff
fi

IFS=. read major minor patch < <(echo $V)

sed \
	-e "s/@OGDI_MAJOR@/$major/" \
	-e "s/@OGDI_MINOR@/$minor/" \
	-e "s#^INST_INCLUDE.*#&/ogdi#" \
	-e "/AUTOCONF_CC = /d" \
        -e "s#^cp \$(TARGETGEN) \$(INST_LIB)\$#&/ogdi#" \
	-e "s#^.*mkdir -p \$(INST_LIB)\$#&/ogdi#" \
	../config/common.mak.in >../config/common.mak

vs2019env

cd ..

make TOPDIR=$(cygpath -am $PWD) TARGET=win64 OVERRIDE_COMMON_MAK=yes \
	FG=release \
	prefix="$(cygpath -am osgeo4w/install)" \
	CPP_RELEASE="/I$(cygpath -am include/win32) /D_AMD64_=1 /D_CRT_SECURE_NO_WARNINGS=1 /D_WINREG_=1 /DDUMMY_NAD_CVT" \
	ZLIB_SETTING=external ZLIB_INCLUDE="-I$(cygpath -am osgeo4w/osgeo4w/include)" ZLIB_LINKLIB="$(cygpath -am osgeo4w/osgeo4w/lib/zlib.lib)" \
	EXPAT_SETTING=external EXPAT_INCLUDE="-I$(cygpath -am osgeo4w/osgeo4w/include)" EXPAT_LINKLIB="$(cygpath -am osgeo4w/osgeo4w/lib/libexpat.lib)" \
	all install

cd osgeo4w

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "OGDI data access library (mainly for VPF reading)"
ldesc: "OGDI data access library (mainly for VPF reading)"
category: Libs
requires: msvcrt2019 expat zlib
maintainer: $MAINTAINER
EOF

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "OGDI data access library (Development)"
ldesc: "OGDI data access library (Development)"
category: Libs
requires: $P
maintainer: $MAINTAINER
external-source: $P
EOF

cp ../LICENSE $R/$P-$V-$B.txt
cp ../LICENSE $R/$P-devel/$P-devel-$V-$B.txt


tar -cjf $R/$P-$V-$B.tar.bz2 \
	--absolute-names \
	--xform s,../bin/win64,bin, \
	../bin/win64/*.dll

tar -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	--absolute-names \
	--xform s,install/include,include, \
	--xform s,../external/rpc_win32,include/ogdi, \
	--xform s,../lib/win64,lib, \
	install/include \
	../external/rpc_win32/rpc \
	../lib/win64/*.lib
			
tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh osgeo4w/diff

endlog
