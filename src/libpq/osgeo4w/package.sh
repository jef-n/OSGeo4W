export P=libpq
export V=13.0
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="openssl-devel zlib-devel libiconv-devel"

# perl also used in openssl and qt5
SBPERL=5.32.0.1

source ../../../scripts/build-helpers

startlog

[ -f postgresql-$V.tar.bz2 ] || wget https://ftp.postgresql.org/pub/source/v$V/postgresql-$V.tar.bz2
[ -f ../Makefile ] || tar -C .. -xjf postgresql-$V.tar.bz2 --xform "s,postgresql-$V,.,"

if ! [ -d perl ]; then
	wget -c http://strawberryperl.com/download/$SBPERL/strawberry-perl-$SBPERL-64bit-portable.zip
	mkdir perl
	cd perl
	unzip ../strawberry-perl-$SBPERL-64bit-portable.zip
	cd ..
fi

cat <<EOF >../src/tools/msvc/config.pl
# Configuration arguments for vcbuild.
use strict;
use warnings;

our \$config = {
	openssl   => '$(cygpath -aw osgeo4w)',
	iconv     => '$(cygpath -aw osgeo4w)',
	zlib      => '$(cygpath -aw osgeo4w)',
};

sub confess {
	warn "CONFESS SKIPPED: @_";
	return 1;
}

sub croak {
	warn "CROAK SKIPPED: @_";
	return 1;
}

sub die {
	warn "DIE SKIPPED: @_";
	return 1;
}

1;
EOF

(
	# meet postgresql's expectations
	cp osgeo4w/lib/zlib.lib osgeo4w/lib/zdll.lib
	cp osgeo4w/lib/iconv.dll.lib osgeo4w/lib/iconv.lib

	vs2019env
	fetchenv perl/portableshell.bat /SETENV

	cd ../src/tools/msvc
	cmd /c build.bat libpq psql
	cmd /c install.bat $(cygpath -aw $OSGEO4W_PWD/install) client

	# clean empty directories
	find install -depth -type d -exec rmdir {} \; 2>/dev/null || true
)

cd $OSGEO4W_PWD/install

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "The libpq library for accessing PostgreSQL + psql commandline client"
ldesc: "The libpq library for accessing PostgreSQL + psql commandline client"
maintainer: $MAINTAINER
category: Libs Commandline_Utilities
requires: msvcrt2019 openssl libiconv zlib
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
	bin/psql.exe

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
	--exclude share/pg_service.conf.sample \
	include \
	lib \
	share/psqlrc.sample

cd ..

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
