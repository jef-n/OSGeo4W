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

export OSGEO4W_REP OSGEO4W_SKIP_UPLOAD

[ -f .buildenv ] && source .buildenv

if [ "$TX_TOKEN" = "none" ]; then TX_TOKEN=; fi
if [ "$OSGEO4W_SKIP_UPLOAD" = "0" ]; then OSGEO4W_SKIP_UPLOAD=; fi
if [ "$OSGEO4W_SKIP_CLEAN" = "0" ]; then OSGEO4W_SKIP_CLEAN=; fi

PKGS=$(perl scripts/build-inorder.pl $* | paste -d" " -s)

echo $(date): REPOSITORY: $OSGEO4W_REP
echo $(date): BUILDING: $PKGS

ok=1
P=$PWD
for i in $PKGS; do
	d=${i#-}

	if [ -f $P/tmp/$d.done ]; then
		echo $(date): $d ALREADY DONE
		continue
	fi

	cd src/$d/osgeo4w
	echo $(date): $d BUILDING
	log=$P/tmp/$d.log
	mkdir -p $P/tmp
	if bash -x package.sh 2>&1 | sed -e 's#\\#/#g' -e 's#\([A-Z]\)://#//\L\1/#g' -e  's#\([A-Z]\):/#/\L\1/#g' >$log; then
		echo $(date): $d SUCCEEDED | tee -a $log
		touch $P/tmp/$i.done
	else
		r=$?
		echo $(date): $d FAILED WITH $r | tee -a $log
		[ "$OSGEO4W_CONTINUE_BUILD" ] || exit 1
		ok=0
	fi
	cd ../../..
done

[ "$ok" ] || exit 1
