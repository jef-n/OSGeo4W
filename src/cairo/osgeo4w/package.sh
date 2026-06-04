export P=cairo
export V=1.18.4
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="zlib-devel libpng-devel freetype-devel python3-core python3-pip"
export PACKAGES="cairo cairo-devel"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.xz ] || wget https://cairographics.org/releases/$P-$V.tar.xz
[ -f ../$P-$V/meson.build ] || tar -C .. -xJf $P-$V.tar.xz
[ -f ../$P-$V/patched ] || {
	patch -d ../$P-$V -p1 --dry-run <patch
	patch -d ../$P-$V -p1 <patch >../$P-$V/patched
}

(
	fetchenv osgeo4w/bin/o4w_env.bat
	cmakeenv
	ninjaenv
	vsenv

	pip3 install meson

	mkdir -p build install
	cd ../$P-$V

	export INCLUDE="$(cygpath -am ../osgeo4w/osgeo4w/include);$INCLUDE"
	export LIB="$(cygpath -am ../osgeo4w/osgeo4w/lib);$LIB"

	PNG_DIR=$(cygpath -am ../osgeo4w/osgeo4w/lib) \
	meson setup ../osgeo4w/build \
		--wrap-mode=nofallback \
		--force-fallback-for=pixman \
		-Dglib=disabled \
		-Dlzo=disabled \
		-Dfreetype=enabled \
		-Dpng=enabled \
		-Dzlib=enabled \
		--prefix=$(cygpath -am ../osgeo4w/install)

	ninja -C ../osgeo4w/build
	ninja -C ../osgeo4w/build install
)

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "Cairo is a 2D graphics library with support for multiple output devices (Runtime)"
ldesc: "Cairo is a 2D graphics library with support for multiple output devices (Runtime)"
category: Libs
requires: zlib libpng
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	--exclude "*.pdb" \
	bin

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "Cairo is a 2D graphics library with support for multiple output devices (Development)"
ldesc: "Cairo is a 2D graphics library with support for multiple output devices (Development)"
category: Libs
requires: $P
external-source: $P
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	--exclude "*.dll" \
	bin \
	include \
	lib

cp ../$P-$V/COPYING $R/$P-$V-$B.txt
cp ../$P-$V/COPYING $R/$P-devel/$P-devel-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh osgeo4w/patch

endlog
