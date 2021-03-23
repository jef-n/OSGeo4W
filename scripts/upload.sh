#!/bin/bash

set -e

: ${OSGEO4W_RSYNC_OPT:=}

export D=$(cygpath -a "$(dirname "${BASH_SOURCE[0]}")")

source "$D/build-helpers"

if [ -z "$OSGEO4W_REP" ]; then
	echo $0: No repo >&2
	exit 1
fi

perl $D/upload.pl
