export P=gsl
export V=2.6
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none

export sha=f682a568d3a8724ffec01edc72c40423444b1e8b

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget -O $P-$V.tar.gz https://github.com/BrianGladman/gsl/archive/$sha.tar.gz
[ -f ../build.vc ] || tar -C .. -xzf $P-$V.tar.gz --xform "s,^gsl-$sha,.,"

vs2019env

cd ../build.vc
for i in gslhdrs cblasdll gsldll; do
	devenv gsl.dll.sln /Project $i /Build "Release|x64"
done

cd ../osgeo4w

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

mkdir -p install/bin install/include/gsl install/lib

cp -r ../gsl install/include/
cp ../dll/x64/Release/{cblas,gsl}.dll install/bin
cp ../dll/x64/Release/{cblas,gsl}.lib install/lib

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
