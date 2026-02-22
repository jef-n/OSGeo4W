export P=sfcgal
export V=2.2.0
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="base boost-devel"
export PACKAGES="sfcgal sfcgal-devel"

source ../../../scripts/build-helpers

startlog

pv=${P^^}-v$V
[ -f $pv.tar.gz ] || wget -q https://gitlab.com/$P/${P^^}/-/archive/v$V/$pv.tar.gz
[ -d ../$pv ] || tar -C .. -xzf $pv.tar.gz

export cp=CGAL cv=6.1.1
export cva=$cp-$cv-win64-auxiliary-libraries-gmp-mpfr.zip
[ -f $cp-$cv.tar.gz ] || wget -O $cp-$cv.tar.gz https://github.com/$cp/${cp,,}/archive/refs/tags/v$cv.tar.gz
[ -d ../$cp-$cv ] || tar -C .. -xzf $cp-$cv.tar.gz

[ -f $cva ] || wget https://github.com/$cp/${cp,,}/releases/download/v$cv/$cva
[ -d ../$cp-$cv/auxiliary ] || unzip -d ../$cp-$cv $cva

(
	set -e

	fetchenv osgeo4w/bin/o4w_env.bat

	vsenv
	cmakeenv
	ninjaenv

	[ -n "$OSGEO4W_SKIP_CLEAN" ] || rm -rf build-$V
	mkdir -p build-$V
	cd build-$V

	rm -rf install

	CXXFLAGS="/wd4702" \
	cmake \
		-G Ninja \
		-D CMAKE_BUILD_TYPE=Release \
		-D CMAKE_INSTALL_PREFIX=../install \
		-D SFCGAL_USE_STATIC_LIBS=OFF \
		-D CGAL_Boost_USE_STATIC_LIBS=ON \
		-D CGAL_CMAKE_EXACT_NT_BACKEND=GMP_BACKEND \
		-D CGAL_DIR="$(cygpath -am ../../$cp-$cv)" \
		-D GMP_INCLUDE_DIR="$(cygpath -am ../../$cp-$cv/auxiliary/gmp/include)" \
		-D GMP_LIBRARIES="$(cygpath -am ../../$cp-$cv/auxiliary/gmp/lib/gmp.lib)" \
		-D MPFR_INCLUDE_DIR="$(cygpath -am ../../$cp-$cv/auxiliary/gmp/include)" \
		-D MPFR_LIBRARIES="$(cygpath -am ../../$cp-$cv/auxiliary/gmp/lib/mpfr.lib)" \
		../../$pv

	cmake --build .
	cmake --build . --target install
	cmakefix ../install
)

R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "SFCGAL library"
ldesc: "The SFCGAL library (including mpfr & gmp)"
maintainer: $MAINTAINER
category: Libs
requires: 
EOF

tar -C install \
	-cjvf $R/$P-$V-$B.tar.bz2 \
	--xform "s,$cp-$cv/Installation/,," \
	--xform "s,$cp-$cv/auxiliary/gmp/,," \
	../../$cp-$cv/Installation/include \
	../../$cp-$cv/Installation/lib \
	../../$cp-$cv/auxiliary/gmp/bin/gmp-10.dll \
	../../$cp-$cv/auxiliary/gmp/bin/mpfr-6.dll \
	bin

cp ../$pv/LICENSE $R/$P-$V-$B.txt

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "SFCGAL library (development)"
ldesc: "The SFCGAL library (including CGAL headers)"
maintainer: $MAINTAINER
category: Libs
requires: $P boost-devel
external-source: $P
EOF

tar -C install \
	-cjvf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	--xform "s,$cp-$cv/Installation/,," \
	../../$cp-$cv/Installation/include \
	../../$cp-$cv/Installation/lib \
	include lib

cp ../$pv/LICENSE $R/$P-devel/$P-devel-$V-$B.txt

endlog
