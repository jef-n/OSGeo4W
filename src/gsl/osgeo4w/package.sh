export P=gsl
export V=tbd
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none
export PACKAGES="gsl gsl-devel"

source ../../../scripts/build-helpers

startlog

[ -f master.tar.gz ] || wget https://github.com/BrianGladman/gsl/archive/master.tar.gz
[ -f ../$P/build.vc ] || tar -C .. -xzf master.tar.gz --xform "s,^gsl-master,$P,"

V=$(sed -ne "s/^AC_INIT(\\[$P\\],\\[\\(.*\\)\\])/\1/p" ../$P/configure.ac)

vsenv

cd ../$P/build.vc

msbuild.exe gsl.dll.sln -t:"gslhdrs;cblasdll;gsldll" -p:Configuration=Release

cd ../../osgeo4w

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

mkdir -p install/bin install/include/gsl install/lib

cp -r ../$P/gsl install/include/
cp ../$P/dll/x64/Release/{cblas,gsl}.dll install/bin
cp ../$P/dll/x64/Release/{cblas,gsl}.lib install/lib

cat <<EOF >$R/setup.hint
sdesc: "GNU Scientific Library (GSL)"
ldesc: "GNU Scientific Library (GSL)"
maintainer: $MAINTAINER
category: Libs
requires: msvcrt2019
EOF

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "GNU Scientific Library (GSL; Development)"
ldesc: "GNU Scientific Library (GSL; Development)"
maintainer: $MAINTAINER
category: Libs
requires: $P
external-source: $P
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 bin
tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 include lib
tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
