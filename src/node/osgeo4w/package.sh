export P=node
export V=20.11.1
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none
export PACKAGES="node"

source ../../../scripts/build-helpers

startlog

[ -f "$P-v$V-win-x64.zip" ] || wget https://${P}js.org/dist/v$V/$P-v$V-win-x64.zip
[ -d "$P-v$V-win-x64" ] || unzip $P-v$V-win-x64.zip
[ -d "$P-v$V-win-x64" ]


export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R

cat <<EOF >$R/setup.hint
sdesc: "node.js"
ldesc: "Node.js® is a JavaScript runtime built on Chrome's V8 JavaScript engine."
maintainer: $MAINTAINER
category: Libs
requires:
EOF

for i in npm npx; do
	cat <<EOF >$i.cmd
@echo off
call "%~dp0\\o4w_env.bat"
"%OSGEO4W_ROOT%\\apps\\node\\$i.cmd" %*
EOF
done

cat <<EOF >node.cmd
@echo off
call "%~dp0\\o4w_env.bat"
"%OSGEO4W_ROOT%\\apps\\node\\node.exe" %*
EOF

tar -cjf $R/$P-$V-$B.tar.bz2 \
	--xform s,^node-v$V-win-x64,apps/node, \
	--xform s,^npm.cmd,bin/npm.cmd, \
	--xform s,^npx.cmd,bin/npx.cmd, \
	--xform s,^node.cmd,bin/node.cmd, \
	npm.cmd \
	npx.cmd \
	node.cmd \
	node-v$V-win-x64

tar -cjf $R/$P-$V-$B-src.tar.bz2 \
	-C .. \
	osgeo4w/package.sh

cp node-v$V-win-x64/LICENSE $R/$P-$V-$B.txt

endlog
