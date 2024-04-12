export P=opencl
export V=2023.12.14
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none
export PACKAGES="opencl opencl-devel"

source ../../../scripts/build-helpers

startlog

p=OpenCL-SDK-v$V-Source
[ -f $p.tar.gz ] || wget https://github.com/KhronosGroup/OpenCL-SDK/releases/download/v$V/$p.tar.gz
[ -d ../$p ] || tar -C .. -xzf $p.tar.gz

vsenv
cmakeenv
ninjaenv

mkdir -p build install

cd build

cmake -G Ninja \
	-D CMAKE_BUILD_TYPE=Release \
	-D CMAKE_INSTALL_PREFIX=$(cygpath -am ../install) \
	-D BUILD_TESTING=OFF \
	-D BUILD_DOCS=OFF \
	-D BUILD_EXAMPLES=OFF \
	-D BUILD_TESTS=OFF \
	-D OPENCL_SDK_BUILD_SAMPLES=OFF \
	-D OPENCL_SDK_TEST_SAMPLES=OFF \
	../../$p

cmake --build .
cmake --build . --target install
cmakefix ../install

cd ..

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cp ../$p/LICENSE $R/$P-$V-$B.txt
cp ../$p/LICENSE $R/$P-devel/$P-devel-$V-$B.txt

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

mkdir -p install/etc/{postinstall,preremove}

cat <<EOF >install/etc/postinstall/$P.bat
dllupdate -copy -reboot "%OSGEO4W_ROOT%\\bin\\opencl.dll"
if exist %WINDIR%\\system32\\opencl.dll del "%OSGEO4W_ROOT%\\bin\\opencl.dll"
EOF

cat <<EOF >install/etc/preremove/$P.bat
dllupdate -unref -reboot "%OSGEO4W_ROOT%\\bin\\opencl.dll"
EOF

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	include \
	share \
	lib

tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	etc \
	bin/opencl.dll

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 \
	osgeo4w/package.sh

endlog
