#!/bin/bash

set -e

export D=$(cygpath -a "$(dirname "${BASH_SOURCE[0]}")")

[ -d "$T" ] || T=$(mktemp -d)
cd $T
mkdir -p $T/packages

NOINIT=1 source "$D/build-helpers"

if [ -z "$OSGEO4W_REP" ]; then
	echo $0: No repo >&2
	exit 1
fi

if [ -z "$OSGEO4W_MAINTAINER" ]; then
	echo $0: No maintainer >&2
	exit 1
fi

log "Using temporary directory $T"

fetchdeps base python3-core python3-pip python3-setuptools

(
	fetchenv $T/osgeo4w/bin/o4w_env.bat
	export PATH=$PATH:/bin

	vs2019env

	for p in "$@"; do
		python $D/pip2o4w.py $p
	done
)
