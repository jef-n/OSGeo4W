export P=grass8
export V=8.2.0
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="gdal-devel proj-devel geos-devel netcdf-devel libjpeg-turbo-devel libpng-devel libpq-devel libtiff-devel sqlite3-devel zstd-devel python3-ply python3-core python3-six python3-pywin32 python3-wxpython wxwidgets-devel liblas-devel"

branch=main

source ../../../scripts/build-helpers

set -o | grep -s "xtrace[	 ]*on" && xtrace=-x || true

startlog

MM=${V%.*}
MM=${MM//./}

[ -f grass-$V.tar.gz ] || wget -O grass-$V.tar.gz https://github.com/OSGeo/grass/archive/refs/tags/$V.tar.gz
[ -f ../grass-$V/configure ] || tar -C .. -xzf grass-$V.tar.gz
[ -f ../grass-$V/patched ] || {
	patch -d ../grass-$V -p1 --dry-run <patch
	patch -d ../grass-$V -p1 <patch
	touch ../grass-$V/patched
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
		mingw-w64-x86_64-openmp \
		mingw-w64-x86_64-cairo
	"
	cmd.exe /c "$cmd" || cmd.exe /c "$cmd" || cmd.exe /c "$cmd"

	cd ../grass-$V

	PACKAGE_POSTFIX=${V%%.*} cmd.exe /c "$(cygpath -aw $OSGEO4W_PWD/msys64/usr/bin/bash) $xtrace mswindows/osgeo4w/package.sh"
)

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R

cp ../grass-$V/mswindows/osgeo4w/package/$P-$V-1.tar.bz2 $R/$P-$V-$B.tar.bz2
cp ../grass-$V/COPYING $R/$P-$V-$B.txt

cat <<EOF >$R/setup.hint
sdesc: "GRASS GIS ${V%.*}"
ldesc: "Geographic Resources Analysis Support System (GRASS GIS ${V%.*})"
category: Desktop
requires: liblas $RUNTIMEDEPENDS avce00 gpsbabel proj python3-gdal python3-matplotlib libtiff python3-wxpython python3-pillow python3-pip python3-ply python3-pyopengl python3-psycopg2-binary python3-six zstd python3-pywin32 gs netcdf wxwidgets
maintainer: $MAINTAINER
EOF

appendversions $R/setup.hint

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh osgeo4w/patch

endlog
