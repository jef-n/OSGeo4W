#!/bin/bash

set -e

export D=$(cygpath -a "$(dirname "${BASH_SOURCE[0]}")")

source "$D/build-helpers"

if [ -z "$OSGEO4W_REP" ]; then
	echo $0: No repo >&2
	exit 1
fi

regen

(
	cd $OSGEO4W_REP
	diff -u x86_64/setup.ini.prev x86_64/setup.ini || true
)
