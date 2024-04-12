export P=api-ms-win-core-path-HACK
export V=0.0.1
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none
export PACKAGES=api-ms-win-core-path-HACK

source ../../../scripts/build-helpers

startlog

cd ..

[ -d $P ] || git clone https://github.com/nalexandru/$P.git
cd $P

(
	set -e

	vsenv

	set -x
	msbuild.exe /p:PlatformToolset=v143,Platform=x64,Configuration=Release api-ms-win-core-path-blender.sln
)

cd ../osgeo4w

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R

cat <<EOF >$R/setup.hint
sdesc: "Hack to make python 3 work on Windows 7"
ldesc: "This is an implementation of api-ms-win-core-path-l1-1-0.dll based on
Wine code. Originally  made to run Blender 2.93 (specifically, Python 3.9) on Windows
7."
maintainer: $MAINTAINER
category: Libs
requires: msvcrt2019 base
EOF

dll=api-ms-win-core-path-l1-1-0.dll

cat <<EOF >../$P/build/x64/release/postinstall.bat
iswindows8orgreater
if errorlevel 1 ren bin\\$dll.w7 $dll
EOF

cat <<EOF >../$P/build/x64/release/preremove.bat
if exist bin\\$dll del bin\\$dll
EOF

tar -C ../$P/build/x64/release -cjf $R/$P-$V-$B.tar.bz2 \
	--xform s,$dll,bin/$dll.w7, \
	--xform s,postinstall.bat,etc/postinstall/$P.bat, \
	--xform s,preremove.bat,etc/preremove/$P.bat, \
	$dll \
	postinstall.bat \
	preremove.bat

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 \
	osgeo4w/package.sh

endlog
