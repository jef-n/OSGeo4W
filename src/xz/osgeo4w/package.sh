export P=xz
export V=5.2.5
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.bz2 ] || wget -c https://tukaani.org/$P/$P-$V.tar.bz2
[ -f ../CMakeLists.txt ] || tar -C .. -xjf $P-$V.tar.bz2 --xform "s,^$P-$V,.,"

vs2019env

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cd ../windows/vs2019

devenv xz_win.sln /upgrade
devenv xz_win.sln /Build "Release|x64" /out ..\\osgeo4w\\build.log

cd ../../osgeo4w
mkdir -p install

cd install
mkdir -p bin lib include

cp ../../windows/vs2019/Release/x64/liblzma_dll/liblzma.dll bin
cp ../../windows/vs2019/Release/x64/liblzma_dll/liblzma.lib lib
cp -a ../../src/liblzma/api/lzma* include

cd ..

cat <<EOF >$R/setup.hint
sdesc: "XZ-format compression library"
ldesc: "XZ-format compression library"
maintainer: $MAINTAINER
requires: msvcrt2019
category: Libs
EOF

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "XZ-format compression library - development files"
ldesc: "XZ-format compression library - development files"
maintainer: $MAINTAINER
category: Libs
requires: $P
external-source: $P
EOF

cp ../COPYING $R/$P-$V-$B.txt

tar -C install -cjvf $R/$P-$V-$B.tar.bz2 bin/liblzma.dll
tar -C install -cjvf $R/$P-devel/$P-devel-$V-$B.tar.bz2 include lib
tar -C .. -cjvf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
