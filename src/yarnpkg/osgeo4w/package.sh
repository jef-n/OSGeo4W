export P=yarnpkg
export V=1.22.17
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none

source ../../../scripts/build-helpers

startlog

[ -f yarn-v$V.tar.gz ] || wget https://github.com/yarnpkg/yarn/releases/download/v$V/yarn-v$V.tar.gz
[ -d yarn-v$V ] || tar xzf yarn-v$V.tar.gz
[ -d yarn-v$V ]

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R

cat <<EOF >$R/setup.hint
sdesc: "Fast, reliable, and secure dependency management."
ldesc: "Fast, reliable, and secure dependency management."
maintainer: $MAINTAINER
category: Libs
requires: node
EOF

for i in yarn yarnpkg; do
	cat <<EOF >$i.cmd
@echo off
call "%~dp0\\o4w_env.bat"
"%OSGEO4W_ROOT%\\apps\\$P\\bin\\$i.cmd" %*
EOF
done

cp yarn-v$V/LICENSE $R/$P-$V-$B.txt

tar -cjf $R/$P-$V-$B.tar.bz2 \
	--xform s,^yarn-v$V,apps/$P, \
	--xform s,^yarn.cmd,bin/yarn.cmd, \
	--xform s,^yarnpkg.cmd,bin/yarnpkg.cmd, \
	yarn.cmd \
	yarnpkg.cmd \
	yarn-v$V

tar -cjf $R/$P-$V-$B-src.tar.bz2 \
	-C .. \
	osgeo4w/package.sh

endlog
