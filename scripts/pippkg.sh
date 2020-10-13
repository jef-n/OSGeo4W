#!/bin/bash

set -e

export D=$(cygpath -a "$(dirname "${BASH_SOURCE[0]}")")
export PYTHON=Python39

[ -d "$T" ] || T=$(mktemp -d)
cd $T

NOINIT=1 source "$D/build-helpers"

if [ -z "$OSGEO4W_REP" ]; then
	echo $0: No repo >&2
	exit 1
fi

if [ -z "$OSGEO4W_MAINTAINER" ]; then
	echo $0: No maintainer >&2
	exit 1
fi

log "Using $T"

# Install already available packages
fetchdeps base python3-core python3-pip

fetchenv $T/osgeo4w/bin/o4w_env.bat
export PATH=$PATH:/bin

mkdir -p $T/packages

for p in "$@"; do
	log "Downloading $p"
	pip download --only-binary=:all: -d $(cygpath -aw $T/packages) $p
done

for whl in $T/packages/*.whl; do
	base=${whl##*/}
	unzip -p $whl "*/METADATA" >metadata

	name=$(sed -ne "s/^Name: //p" metadata)
	summary=$(sed -ne "s/^Summary: //p" metadata)

	requires=
	while read p; do
		requires="$requires python3-${p%% *}"
	done < <(sed -ne "s/Requires-Dist: //p" metadata)

	P=python3-$name
	V=$(sed -ne "s/^Version: //p" metadata)
	B=$(nextbinary)

	if [ -f "$R/$P-$V-$B.tar.bz2" ] || [ -f "$R/$P-$V-$B-src.tar.bz2" ]; then
		echo "Package: $P-$V-$B already exists"
	else
		cat <<EOF >postinstall.bat
call "%OSGEO4W_ROOT%\\bin\\o4w_env.bat"
pip install "%OSGEO4W_ROOT%\\apps\\$PYTHON\\wheels\\$base"
EOF

		cat <<EOF >preremove.bat
call "%OSGEO4W_ROOT%\\bin\\o4w_env.bat"
pip uninstall $name
del "%OSGEO4W_ROOT%\\apps\\$PYTHON\\wheels\\$base"
EOF

		export R="$OSGEO4W_REP/x86_64/release/python3/$P"
		mkdir -p $R

		cat <<EOF >"$R/setup.hint"
sdesc: "$summary"
ldesc: "$summary

created with pippkg.sh $name
source package is empty
"
maintainer: $OSGEO4W_MAINTAINER
category: Libs
requires: python3-core python3-pip$requires
EOF

		tar -cjf "$R/$P-$V-$B.tar.bz2" \
			--xform "s,postinstall.bat,etc/postinstall/$P.bat," \
			--xform "s,preremove.bat,etc/preremove/$P.bat," \
			--xform "s,${whl#/},apps/Python39/wheels/$base," \
			postinstall.bat \
			preremove.bat \
			$whl

		tar -cjf "$R/$P-$V-$B-src.tar.bz2" \
			-T /dev/null
	fi
done

regen

log "End"
