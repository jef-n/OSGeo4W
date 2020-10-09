export P=msoledbsql
export V=manual
export B=0
export MAINTAINER=JuergenFischer

source ../../../scripts/build-helpers

startlog

wget -q -c -O $P.msi "https://go.microsoft.com/fwlink/?linkid=2129954"

msiexec /a $P.msi /qb "TARGETDIR=$(cygpath -aw extract)"

V=$(echo "extract/Program Files/Microsoft SQL Server/Client SDK/OLEDB"/*)
V=${V##*/}
B=$(nextbinary)

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "Microsoft OLE DB Driver for SQL Server (runtime)"
ldesc: "Microsoft OLE DB Driver for SQL Server (runtime)"
category: Libs
requires: msvcrt2019
maintainer: $MAINTAINER
EOF

cp "extract/Program Files/Microsoft SQL Server/Client SDK/OLEDB/$V/License Terms/License_MSOLEDBSQL_ENU.txt" $R/$P-devel/$P-devel-$V-$B.txt

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "Microsoft OLE DB Driver for SQL Server (Development)"
ldesc: "Microsoft OLE DB Driver for SQL Server (Development)"
category: Libs
requires: $P
external-source: $P
maintainer: $MAINTAINER
EOF

cat <<EOF >postinstall.bat
msiexec /i %OSGEO4W_ROOT%\\bin\\$P.msi /qn IACCEPTMSOLEDBSQLLICENSETERMS=YES
EOF

tar -cjf $R/$P-$V-$B.tar.bz2 \
	--xform "s,postinstall.bat,etc/postinstall/$P.bat," \
	--xform "s,$P.msi,bin/$P.msi," \
	postinstall.bat \
	$P.msi

tar -C "extract/Program Files/Microsoft SQL Server/Client SDK/OLEDB/$V/SDK" -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	--xform "s,Lib/x64,lib," \
	Include/msoledbsql.h \
	Lib/x64/msoledbsql.lib \

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog

