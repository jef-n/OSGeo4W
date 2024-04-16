#!/bin/bash

set -e
set -o pipefail

export PATH=/bin:/usr/bin

if [ -z "$OSGEO4W_REP" ]; then
	b=$(git branch --show-current)
	case $b in
	master)
		export OSGEO4W_REP=$PWD
		cd $OSGEO4W_REP
		;;

	*)
		export OSGEO4W_REP=$TEMP/repo-$b
		export OSGEO4W_SKIP_UPLOAD=1
		mkdir -p "$OSGEO4W_REP"
		;;
	esac
fi

: ${OSGEO4W_SKIP_UPLOAD:=1}
: ${OSGEO4W_SKIP_CLEAN:=1}
: ${OSGEO4W_BUILD_RDEPS:=1}
: ${OSGEO4W_CONTINUE_BUILD:=0}

export OSGEO4W_REP OSGEO4W_SKIP_UPLOAD

build() {
	bash package.sh
}

[ -f .buildenv ] && source .buildenv

if [ "$TX_TOKEN" = "none" ]; then TX_TOKEN=; fi
if [ "$OSGEO4W_SKIP_UPLOAD" = "0" ]; then OSGEO4W_SKIP_UPLOAD=; fi
if [ "$OSGEO4W_SKIP_CLEAN" = "0" ]; then OSGEO4W_SKIP_CLEAN=; fi
if [ "$OSGEO4W_BUILD_RDEPS" = "0" ]; then OSGEO4W_BUILD_RDEPS=; fi
if [ "$OSGEO4W_CONTINUE_BUILD" = "0" ]; then OSGEO4W_CONTINUE_BUILD=; fi

PKGS="$@"

[ -z "$OSGEO4W_BUILD_RDEPS" ] || PKGS=$(perl scripts/build-inorder.pl $PKGS | paste -d" " -s)

echo $(date): REPOSITORY: $OSGEO4W_REP
echo $(date): BUILDING: $PKGS
[ -z "$OSGEO4W_SKIP_UPLOAD" ] || echo $(date): NOT UPLOADING
[ -n "$OSGEO4W_BUILD_RDEPS" ] || echo $(date): NOT BUILDING REVERSE DEPENDENCIES
[ -z "$OSGEO4W_SKIP_CLEAN" ] || echo $(date): SKIPPING CLEANS
[ -z "$OSGEO4W_CONTINUE_BUILD" ] || echo $(date): CONTINUING ON BUILD FAILURES

ok=1
P=$PWD
built=
for i in $PKGS; do
	d=${i#-}

	if [ -f $P/tmp/$d.done ]; then
		echo $(date): $d ALREADY DONE
		continue
	fi

	cd src/$d/osgeo4w

	echo $(date): $d BUILDING

	mkdir -p $P/tmp
	if build; then
		echo $(date): $d SUCCEEDED
		built="${built} $d"
		touch $P/tmp/$i.done
	else
		r=$?
		echo $(date): $d FAILED WITH $r
		[ "$OSGEO4W_CONTINUE_BUILD" ] || exit 1
		ok=0
	fi

	cd ../../..
done

[ -z "$GITHUB_ENV" ] || echo "BUILT_PKGS=${built# }" >>$GITHUB_ENV

[ "$ok" ] || exit 1
