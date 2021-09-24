export P=grass-dev
export PACKAGE_POSTFIX="-dev"
export V=8.0.dev
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="gdal-devel pdal-devel proj-devel geos-devel netcdf-devel libjpeg-devel libpng-devel libpq-devel libtiff-devel sqlite3-devel zstd-devel python3-ply python3-core python3-six python3-pywin32 python3-wxpython wxwidgets-devel"

branch=main

if [ "$CI" ] ; then
cd "$OSGEO4W_REP"
fi

source ../../../scripts/build-helpers

set -o | grep -s "xtrace[	 ]*on" && xtrace=-x || true

startlog

MM=${V%.*}
MM=${MM//./}

[ -f $P-$V.tar.gz ] || wget -O $P-$V.tar.gz https://codeload.github.com/OSGeo/grass/tar.gz/$branch
[ -f ../$P-$V/configure ] || tar -C .. -xzf $P-$V.tar.gz
[ -d ../grass-$branch -a ! -d ../$P-$V ] | mv ../grass-$branch ../$P-$V
[ -f ../$P-$V/patched ] || {
	patch -l -d ../$P-$V -p1 --dry-run <patch
	patch -l -d ../$P-$V -p1 <patch
	touch ../$P-$V/patched
}

msysarch=msys2-base-x86_64-20210604.tar.xz

[ -f $msysarch ] || wget http://repo.msys2.org/distrib/x86_64/$msysarch
[ -d msys64 ] || tar xJf $msysarch

(
	fetchenv osgeo4w/bin/o4w_env.bat
	export OSGEO4W_ROOT_MSYS="${OSGEO4W_ROOT//\\/\/}"
	export OSGEO4W_ROOT_MSYS="/${OSGEO4W_ROOT_MSYS:0:1}/${OSGEO4W_ROOT_MSYS:3}"

	export VCPATH=$(
		vs2019env
		echo ${PATH//\/cygdrive/}
	)

	export PATH="$(cygpath -a msys64/usr/bin):$PATH"

	[ -f msys64/msys2.init ] || {
		cmd.exe /c "bash pacman-key --init"
		cmd.exe /c "bash pacman-key --populate msys2"
		cmd.exe /c "bash /etc/profile"
		touch msys64/msys2.init
	}

	cmd.exe /c pacman --noconfirm -Syuu --needed
	cmd="pacman --noconfirm -S --needed \
		diffutils \
		flex \
		bison \
		make \
		dos2unix \
		tar \
		mingw-w64-x86_64-pkg-config \
		mingw-w64-x86_64-gcc \
		mingw-w64-x86_64-ccache \
		mingw-w64-x86_64-zlib \
		mingw-w64-x86_64-libiconv \
		mingw-w64-x86_64-bzip2 \
		mingw-w64-x86_64-gettext \
		mingw-w64-x86_64-libsystre \
		mingw-w64-x86_64-libtre-git \
		mingw-w64-x86_64-libwinpthread-git \
		mingw-w64-x86_64-libpng \
		mingw-w64-x86_64-pcre \
		mingw-w64-x86_64-fftw \
		mingw-w64-x86_64-lapack \
		mingw-w64-x86_64-cairo
	"
	cmd.exe /c "$cmd" || cmd.exe /c "$cmd" || cmd.exe /c "$cmd"

	cd ../$P-$V

if [ "$CI" ] ; then
	P=$(cygpath -ua "C:/Program Files (x86)\Microsoft Visual Studio/2019/Enterprise/VC/Tools/MSVC/14.29.30133/bin/HostX64/x64/")
	sed -i "3 a export PATH=\"$P:$PATH\"" mswindows/osgeo4w/mklibs.sh
	sed -i "s/dumpbin -exports/dumpbin \/EXPORTS/" mswindows/osgeo4w/mklibs.sh
fi

	cmd.exe /c "$(cygpath -aw $OSGEO4W_PWD/msys64/usr/bin/bash) $xtrace mswindows/osgeo4w/package.sh"
)

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R

cp ../$P-$V/mswindows/osgeo4w/package/$P-$V-1.tar.bz2 $R/$P-$V-$B.tar.bz2
cp ../$P-$V/COPYING $R/$P-$V-$B.txt

cat <<EOF >$R/setup.hint
sdesc: "GRASS GIS 8.0 alpha"
ldesc: "Geographic Resources Analysis Support System (GRASS GIS) 8.0 alpha"
category: Desktop
requires: liblas $RUNTIMEDEPENDS avce00 gpsbabel gs python3-gdal python3-matplotlib libtiff python3-wxpython python3-pillow python3-pip python3-ply python3-pyopengl python3-psycopg2-binary python3-six zstd python3-pywin32 netcdf wxwidgets
maintainer: $MAINTAINER
EOF

appendversions $R/setup.hint

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh osgeo4w/patch

endlog
