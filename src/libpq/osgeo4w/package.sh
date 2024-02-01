export P=libpq
export V=16.1
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="openssl-devel zlib-devel libiconv-devel"

# perl also used in openssl and qt5
SBPERL=5.32.1.1

source ../../../scripts/build-helpers

startlog

[ -f postgresql-$V.tar.bz2 ] || wget https://ftp.postgresql.org/pub/source/v$V/postgresql-$V.tar.bz2
[ -f ../postgresql-$V/Makefile ] || {
	tar -C .. -xjf postgresql-$V.tar.bz2
	patch --dry-run -p1 -d ../postgresql-$V <patch
	patch           -p1 -d ../postgresql-$V <patch
}

if ! [ -d perl ]; then
	wget -c http://strawberryperl.com/download/$SBPERL/strawberry-perl-$SBPERL-64bit-portable.zip
	mkdir perl
	cd perl
	unzip ../strawberry-perl-$SBPERL-64bit-portable.zip
	cd ..
fi

cat <<EOF >../postgresql-$V/src/tools/msvc/config.pl
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

	fetchenv perl/portableshell.bat /SETENV
	vs2019env

	export PATH="$PATH:/c/Program Files (x86)/Microsoft Visual Studio/2019/Community/MSBuild/Current/Bin/amd64/"

	cd ../postgresql-$V/src/tools/msvc
	cmd /c build.bat >libpq.log 2>&1 || { cat libpq.log; false; }
	cmd /c install.bat $(cygpath -aw $OSGEO4W_PWD/install) client || true

	# clean empty directories
	find install -depth -type d -exec rmdir {} \; 2>/dev/null || true
)

cd $OSGEO4W_PWD/install

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "The libpq library for accessing PostgreSQL and command line clients"
ldesc: "The libpq library for accessing PostgreSQL + psql + pg_dump + pg_restore"
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
	--exclude share/pg_service.conf.sample \
	include \
	lib \
	share/psqlrc.sample

cd ..

cp ../postgresql-$V/COPYRIGHT $R/$P-$V-$B.txt
cp ../postgresql-$V/COPYRIGHT $R/$P-devel/$P-devel-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh osgeo4w/patch

endlog
