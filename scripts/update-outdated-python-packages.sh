#!/bin/bash

set -e

if [ -z "$OSGEO4W_REP" ]; then
	if [ -d "x86_64" ]; then
		export OSGEO4W_REP=$PWD
	else
		echo no repository specified
		exit 1
	fi
fi

source scripts/build-helpers

pinned=$(pinnedpypkgs)

[ -f .outdated.dir ] && o4w=$(<.outdated.dir) || { o4w=$(mktemp -d); rm -rf tmp/*.done; echo $o4w >.outdated.dir; }

# get all packages python packages
all=$(
	(
		curl -s $MASTER_REPO/x86_64/setup.ini | sed -ne "/@ python3-/ s/^@ //p"
		sed -ne "/@ python3-/ s/^@ //p" $OSGEO4W_REP/x86_64/setup.ini
	) |
	sort -u |
	paste -d, -s
)

echo "$(date): CHECKING $all IN $o4w"

# repeat until there are no outdated packages left
export i
[ -f .outdated.i ] && i=$(<.outdated.i) || i=0
while :; do
	echo ITERATION:$(( ++i ))
	echo $i >.outdated.i

	# install all python packages
	$OSGEO4W_SCRIPTS/osgeo4w-setup.exe \
		--root $(cygpath -am "$o4w") \
        	--autoaccept \
        	--arch x86_64 \
        	--quiet-mode \
        	--upgrade-also \
        	--only-site \
        	--safe \
        	--no-shortcuts \
        	-s $(cygpath -am $OSGEO4W_REP) \
        	-s $MASTER_REPO \
        	-l $(cygpath -am $OSGEO4W_REP/package-cache) \
		-P $all \
		>$o4w/setup.log.$i 2>&1 || { tail -20 setup.log.$i; exit 1; }

	(
		fetchenv $o4w/bin/o4w_env.bat >$o4w/o4w_env.0.log 2>&1
		pip check || exit 1
	)

	# produce list of (still) outdated packages
	(
		fetchenv $o4w/bin/o4w_env.bat >$o4w/o4w_env.1.log 2>&1
		pip list --outdated | egrep -v "$pinned" >$o4w/outdated.$i || true
	)

	# generate osgeo4w package list for outdated packages
	sed -E -e '1,2d; s/^([^        ]+).*$/python3-\L\1/; s/_/-/g' $o4w/outdated.$i >$o4w/outdated-packages.$i

	# build all outdated python packages, but exclude the non-python packages (dependencies)
	pkgs=$(
		perl scripts/build-inorder.pl $(
			fgrep -xf <(
				fgrep -l "export V=pip" src/python3-*/osgeo4w/package.sh |
				cut -d/ -f2
			) $o4w/outdated-packages.$i
		) |
		fgrep -xf $o4w/outdated-packages.$i |
		tee $o4w/updating.$i
	)

	echo "$(date): PACKAGES: $pkgs"

	if [ "$pkgs" = "$opkgs" ]; then
		# same as before
		break
	fi

	for p in $pkgs; do
		bash build.sh $p
		rm -rf src/$p/osgeo4w/osgeo4w
	done

	cp $o4w/var/log/setup.log.full $o4w/setup.log.full.$i

	if [ $(ls -1 tmp/*.done | wc -l) -eq 2 ]; then
		# no packages built
		break	
	fi

	opkgs=$pkgs
done

# error out if there are outdated packages not built from pip
if fgrep -qxf <(grep -L "export V=pip" src/python3-*/osgeo4w/package.sh | cut -d/ -f2) $o4w/outdated-packages.$i; then
	echo "Outdated packages not built from pip:"
	sed -E -e '1,2d; s/^([^        ]+)(.*)$/python3-\L\1\2/; s/_/-/g' $o4w/outdated.$i |
		egrep "^($(fgrep -xf <(grep -L "export V=pip" src/python3-*/osgeo4w/package.sh | cut -d/ -f2) $o4w/outdated-packages.$i | paste -d"|" -s)) "
	exit 1
fi

rm -r $o4w .outdated.dir .outdated.i tmp/python3-*.done
