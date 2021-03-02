export P=grass
export V=7.8.5
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="gdal-devel proj-devel geos-devel libjpeg-devel libpng-devel libpq-devel libtiff-devel sqlite3-devel zstd-devel python3-core python3-six liblas-devel cairo-devel freetype-devel python3-wxpython"

source ../../../scripts/build-helpers

set -o | grep -s "xtrace[	 ]*on" && xtrace=-x || true

startlog

MM=${V%.*}
MM=${MM//./}

[ -f $P-$V.tar.gz ] || wget http://download.osgeo.org/$P/${P}$MM/source/$P-$V.tar.gz
[ -f ../$P-$V/configure ] || tar -C .. -xzf $P-$V.tar.gz
[ -f patched ] || {
	patch -l -d ../$P-$V -p1 --dry-run <patch
	patch -l -d ../$P-$V -p1 <patch
	touch patched
}

msysarch=msys2-base-x86_64-20200903.tar.xz

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
		cmd.exe /c bash pacman-key --init
		cmd.exe /c bash pacman-key --populate msys2
		cmd.exe /c bash /etc/profile
		touch msys64/msys2.init
	}

	cmd.exe /c pacman --noconfirm -Syuu --needed
	cmd.exe /c pacman --noconfirm -S --needed \
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
		mingw-w64-x86_64-fftw

	cd ../$P-$V

	cmd.exe /c $(cygpath -aw $OSGEO4W_PWD/msys64/usr/bin/bash) $xtrace mswindows/osgeo4w/package.sh
)

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R

cp ../$P-$V/mswindows/osgeo4w/package/$P-$V-1.tar.bz2 $R/$P-$V-$B.tar.bz2
cp ../$P-$V/COPYING $R/$P-$V-$B.txt

cat <<EOF >$R/setup.hint
sdesc: "GRASS GIS"
ldesc: "Geographic Resources Analysis Support System (GRASS GIS)"
category: Desktop
requires: liblas $RUNTIMEDEPENDS avce00 gpsbabel gs python3-gdal python3-matplotlib libtiff python3-wxpython python3-pillow python3-pip python3-ply python3-pyopengl cairo python3-psycopg2-binary python3-six zstd python3-pywin32 freetype
maintainer: $MAINTAINER
EOF

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh osgeo4w/patch

endlog
