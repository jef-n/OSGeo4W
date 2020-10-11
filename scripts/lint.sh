#!/bin/bash

declare -a pkgs
declare -A ok
declare -A nok

for d in src/*; do
	if ! [ -d "$d" ]; then
		echo "$d: not a directory"
		continue
	fi

	pkg=${d#src/}

	pkgs+=($pkg)
	nok+=([$pkg]=1)

	if ! [ -d "$d/osgeo4w" ]; then
		echo "$d: no osgeo4w directory"
		continue
	fi

	if ! [ -f "$d/osgeo4w/package.sh" ]; then
		echo "$d: osgeo4w/package.sh not found"
		continue
	fi

	e=0
	for p in "source ../../../scripts/build-helpers" "startlog" "endlog"; do
		if ! fgrep -q -x "$p" $d/osgeo4w/package.sh; then
			echo "$d: '$p' not found"
			(( e++ ))
			continue
		fi
	done

	if (( e > 0 )); then
		continue
	fi

	(
		export P= V= B= MAINTAINER= BUILDDEPENDS=
		eval $(sed -ne "1,/^$/p" $d/osgeo4w/package.sh)

		e=0
		for v in P V B MAINTAINER BUILDDEPENDS; do
			if eval [ -z \"\$$v\" ]; then
				echo "$d: $v not set"
				(( e++ ))
			fi
		done

		if (( e > 0 )); then
			sed -ne "1,/^$/p" $d/osgeo4w/package.sh
		fi
	)

	ok+=([$pkg]=1)
	unset nok[$pkg]
done

echo "Checked: ${pkgs[@]}"
echo "OK: ${!ok[@]}"

if (( ${#nok[@]} > 0 )); then
	echo "NOK: ${!nok[@]}"
	exit 1
fi
