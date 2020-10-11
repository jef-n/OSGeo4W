export P=msodbcsql
export V=manual
export B=0
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none

source ../../../scripts/build-helpers

startlog

wget -q -c -O $P.msi "https://go.microsoft.com/fwlink/?linkid=2137027"

msiexec /a $P.msi /qb "TARGETDIR=$(cygpath -aw extract)"

v=$(echo "extract/Program Files/Microsoft SQL Server/Client SDK/ODBC/"*)
v=${v##*/}

major=${v%?}
minor=${v#$major}
V=$major.$minor
B=$(nextbinary)

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "Microsoft ODBC Driver for SQL Server (runtime)"
ldesc: "Microsoft ODBC Driver for SQL Server (runtime)"
category: Libs
requires: msvcrt2019
maintainer: $MAINTAINER
EOF

cp "extract/Program Files/Microsoft SQL Server/Client SDK/ODBC/$v/License Terms/License_msodbcsql_ENU.txt" $R/$P-devel/$P-devel-$V-$B.txt

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "Microsoft ODBC Driver for SQL Server (Development)"
ldesc: "Microsoft ODBC Driver for SQL Server (Development)"
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

tar -C "extract/Program Files/Microsoft SQL Server/Client SDK/ODBC/$v/SDK" -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	--xform "s,Lib/x64,lib," \
	Include/msodbcsql.h \
	Lib/x64/msodbcsql$major.lib \

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
