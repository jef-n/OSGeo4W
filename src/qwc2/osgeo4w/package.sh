P=qwc2
V=$(date +%Y%m%d)
B=next
MAINTAINER=JuergenFischer
export BUILDDEPENDS="base yarnpkg"

source ../../../scripts/build-helpers

startlog

[ -d ../qwc2-demo-app ] || git clone --recursive https://github.com/qgis/qwc2-demo-app.git ../qwc2-demo-app

cd ../qwc2-demo-app

git clean -f
git reset --hard
git pull --recurse-submodules

V=$(date +%Y%m%d)-$(git log -1 --pretty=%h)

fetchenv ../osgeo4w/osgeo4w/bin/o4w_env.bat

export PATH="$(cygpath -a node_modules/.bin):$PATH"

yarn.cmd install
yarn.cmd run tsupdate
yarn.cmd run themesconfig
yarn.cmd run iconfont
webpack.cmd --mode production --progress

sed -e "s#dist/QWC2App.js#&?v=$(git log -1 --pretty='%h')#" index.html >../osgeo4w/index.html

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R

cat >$R/setup.hint <<EOF
sdesc: "QGIS webclient 2"
ldesc: "QGIS webclient 2"
category: Web
requires: yarnpkg apache
EOF

tar -cjf $R/$P-$V-$B.tar.bz2 \
	--xform s,^qwc2-demo-app/prod,apps/qwc2, \
	--xform s,^osgeo4w/index.html,apps/qwc2/index.html, \
	--exclude qwc2-demo-app/prod/index.html \
	../osgeo4w/index.html \
	../qwc2-demo-app/prod

tar -cjf $R/$P-$V-$B-src.tar.bz2 \
	-C .. \
	osgeo4w/package.sh

endlog
