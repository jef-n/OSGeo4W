export P=libpq
export V=17.2
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="openssl-devel zlib-devel lz4-devel zstd-devel libiconv-devel python3-core python3-pip"
export PACKAGES="libpq libpq-devel"

source ../../../scripts/build-helpers

startlog

[ -f postgresql-$V.tar.bz2 ] || wget https://ftp.postgresql.org/pub/source/v$V/postgresql-$V.tar.bz2

(
	fetchenv osgeo4w/bin/o4w_env.bat
	cmakeenv
	ninjaenv
	vsenv

	pip3 install meson

	mkdir -p build install
	cd ../postgresql-$V
	meson setup ../osgeo4w/build --prefix=$(cygpath -am ../osgeo4w/install)

	ninja -C ../osgeo4w/build
	ninja -C ../osgeo4w/build install
)

cd $OSGEO4W_PWD/install

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "The libpq library for accessing PostgreSQL and command line clients"
ldesc: "The libpq library for accessing PostgreSQL + psql + pg_dump + pg_restore"
maintainer: $MAINTAINER
category: Libs Commandline_Utilities
requires: msvcrt2019 openssl libiconv zlib zstd lz4
EOF

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "The libpq library for accessing PostgreSQL (Development)"
ldesc: "The libpq library for accessing PostgreSQL (Development)"
maintainer: $MAINTAINER
category: Libs
requires: $P
external-source: $P
maintainer: $MAINTAINER
EOF

tar -cjf $R/$P-$V-$B.tar.bz2 \
	bin/libpq.dll \
	bin/psql.exe \
	bin/pg_dump.exe \
	bin/pg_dumpall.exe \
	bin/pg_restore.exe

tar -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	--exclude include/server \
	--exclude include/informix \
	--exclude "include/ecp*" \
	--exclude "include/pgtypes*" \
	--exclude include/sql3types.h \
	--exclude include/sqlca.h \
	--exclude include/sqlda-compat.h \
	--exclude include/sqlda-native.h \
	--exclude include/sqlda.h \
	--exclude lib/libpq.dll \
	--exclude lib/libpgcommon.lib \
	--exclude lib/libpgport.lib \
	bin/pg_config.exe \
	include \
	lib \
	share/postgresql/pg_service.conf.sample \
	share/postgresql/psqlrc.sample

cd ..

cp ../postgresql-$V/COPYRIGHT $R/$P-$V-$B.txt
cp ../postgresql-$V/COPYRIGHT $R/$P-devel/$P-devel-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
