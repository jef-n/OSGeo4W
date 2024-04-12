export P=python3-psycopg2
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-devel libpq-devel"
export PACKAGES="python3-psycopg2 python3-psycopg2-binary"

source ../../../scripts/build-helpers

startlog

vsenv
cmakeenv
ninjaenv

cat <<EOF >pip.env
export LIB="$(cygpath -am osgeo4w/lib);\$LIB"
export INCLUDE="$(cygpath -am osgeo4w/include);\$INCLUDE"
EOF

PACKAGES=$P adddepends="libpq" packagewheel

export R=$OSGEO4W_REP/x86_64/release/python3/$P-binary
mkdir -p $R

cat <<EOF >$R/setup.hint
sdesc: "PostgreSQL database adapter for Python (transitional package)"
ldesc: "PostgreSQL database adapter for Python (transitional package)"
category: _obsolete
requires: $P
maintainer: $MAINTAINER
external-source: $P
EOF

d=$(mktemp -d)
tar -C $d -cjf $R/$P-binary-$V-$B.tar.bz2 .
rmdir $d

endlog
