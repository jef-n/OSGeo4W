#!/bin/bash

set -e
set -x

export PATH=/bin:/usr/bin:$(/bin/cygpath --sysdir)

: ${GIT_REPO:=https://github.com/jef-n/OSGeo4W}
: ${GIT_BRANCH:=master}

mkdir -p $HOME

[ -d .git ] || {
	git config --global --add safe.directory $PWD
	git init .
	git remote add origin $GIT_REPO
	git fetch origin
	rm -f bootstrap.sh
	git checkout -f -t origin/$GIT_BRANCH
}

git pull --rebase

bash scripts/build.sh "$@"
