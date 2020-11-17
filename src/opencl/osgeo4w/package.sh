export P=opencl
export V=2.0.10
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget -q -O $P-$V.tar.gz https://github.com/KhronosGroup/OpenCL-Headers/archive/master.tar.gz
[ -f cl2.hpp ] || wget -O cl2.hpp https://github.com/KhronosGroup/OpenCL-CLHPP/releases/download/v$V/cl2.hpp

[ -d include ] || tar -xzvf $P-$V.tar.gz \
	--xform s,OpenCL-Headers-master/LICENSE,LICENSE, \
	--xform s,OpenCL-Headers-master/,include/, \
	OpenCL-Headers-master/LICENSE \
	OpenCL-Headers-master/CL/
[ -f include/CL/cl2.hpp ] || cp cl2.hpp include/CL/

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cp LICENSE $R/$P-$V-$B.txt
cp LICENSE $R/$P-devel/$P-devel-$V-$B.txt

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "KhronosGroup OpenCL development files"
ldesc: "KhronosGroup OpenCL development files"
maintainer: $MAINTAINER
category: Libs
requires: $P
external-source: $P
EOF

cat <<EOF >$R/setup.hint
sdesc: "KhronosGroup OpenCL runtime"
ldesc: "KhronosGroup OpenCL runtime"
maintainer: $MAINTAINER
category: Libs
requires: 
EOF

mkdir -p etc/postinstall etc/preremove

cat <<EOF >etc/postinstall/$P.bat
dllupdate -copy -reboot "%OSGEO4W_ROOT%\bin\opencl.dll"
if exist %WINDIR%\system32\opencl.dll del "%OSGEO4W_ROOT%\bin\opencl.dll"
EOF

cat <<EOF >etc/preremove/$P.bat
dllupdate -unref -reboot "%OSGEO4W_ROOT%\bin\opencl.dll"
EOF

tar -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	--xform s,opencl.lib,lib/opencl.lib, \
	include/CL \
	opencl.lib

tar -cjf $R/$P-$V-$B.tar.bz2 \
	--xform s,opencl.dll,bin/opencl.dll, \
	etc/postinstall/ \
	etc/preremove/ \
	opencl.dll

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 \
	osgeo4w/package.sh \
	osgeo4w/opencl.lib \
	osgeo4w/opencl.dll

endlog
