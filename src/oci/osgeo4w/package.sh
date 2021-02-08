export P=oci
export V=manual
export B=0
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none

source ../../../scripts/build-helpers

startlog

wget -q -c https://download.oracle.com/otn_software/nt/instantclient/instantclient-basiclite-windows.zip
mkdir -p basic
unzip -q -o -d basic instantclient-basiclite-windows.zip

V=$(echo basic/instantclient_*)
V=${V#basic/instantclient_}
V=${V//_/.}
nextbinary

[ -d basic/instantclient_${V/./_} ]

wget -q -c https://download.oracle.com/otn_software/nt/instantclient/instantclient-sdk-windows.zip
mkdir -p sdk
unzip -q -o -d sdk instantclient-sdk-windows.zip
[ -d sdk/instantclient_${V/./_} ]

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "Oracle Instant Client"
ldesc: "Oracle Instant Client -- a C API for connecting and interacting with the Oracle Database"
category: Libs
requires: msvcrt2019
maintainer: $MAINTAINER
EOF

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "Oracle Instant Client (Development)"
ldesc: "Oracle Instant Client -- a C API for connecting and interacting with the Oracle Database (headers and library)"
category: Libs
requires: $P
external-source: $P
maintainer: $MAINTAINER
EOF

tar -cjf $R/$P-$V-$B.tar.bz2 \
	--xform "s,basic/instantclient_${V//./_},bin," \
	basic/instantclient_${V//./_}/oci.dll

tar -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	--xform "s,sdk/instantclient_${V//./_}/sdk/lib/msvc,lib," \
	--xform "s,sdk/instantclient_${V//./_}/sdk/,," \
	--exclude "occi*.h" \
	sdk/instantclient_${V//./_}/sdk/include \
	sdk/instantclient_${V//./_}/sdk/lib/msvc/oci.lib

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

cp basic/instantclient_${V//./_}/BASIC_LITE_LICENSE $R/$P-$V-$B.txt
cp sdk/instantclient_${V//./_}/SDK_LICENSE $R/$P-devel/$P-devel-$V-$B.txt

endlog

exit


