export P=grass
export V=8.4.1
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="gdal-devel proj-devel geos-devel netcdf-devel libjpeg-turbo-devel libpq-devel libpng-devel libtiff-devel sqlite3-devel zstd-devel python3-ply python3-core python3-six python3-pywin32 python3-wxpython liblas-devel cairo-devel freetype-devel"
export PACKAGES="grass"

REPO=https://github.com/OSGeo/grass
p=grass-$V
branch=main

source ../../../scripts/build-helpers

set -o | grep -s "xtrace[	 ]*on" && xtrace=-x || true

startlog

MM=${V%.*}
MM=${MM//./}

[ -f $p.tar.gz ] || wget -O $p.tar.gz $REPO/archive/refs/tags/$V.tar.gz
[ -f ../$p/configure ] || tar -C .. -xzf $p.tar.gz
[ -f ../$p/patched ] || {
	patch -d ../$p -p1 --dry-run <patch
	patch -d ../$p -p1 <patch >../$p/patched
}

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R

msysarch=msys2-base-x86_64-20241116.tar.xz

[ -f $msysarch ] || wget https://repo.msys2.org/distrib/x86_64/$msysarch
if ! [ -d msys64 ]; then
	tar xJf $msysarch

	cat >init.sh <<EOF
#!/bin/bash

exec >init.log 2>&1

export PATH=/usr/bin

pacman-key --init
pacman-key --populate msys2
bash /etc/profile
pacman --noconfirm -Syuu --needed

touch msys64/msys2.init
EOF

	cygstart -w $(cygpath -aw msys64/usr/bin/bash.exe) $(cygpath -am init.sh) || true
fi

(
	set -e

	fetchenv osgeo4w/bin/o4w_env.bat
	export OSGEO4W_ROOT_MSYS="${OSGEO4W_ROOT//\\/\/}"
	export OSGEO4W_ROOT_MSYS="/${OSGEO4W_ROOT_MSYS:0:1}/${OSGEO4W_ROOT_MSYS:3}"

	export VCPATH=$(
		vsenv >/dev/null
		echo ${PATH//\/cygdrive/}
	)

	MSYSPATH=$(cygpath -a msys64/usr/bin):$OSGEO4W_ROOT_MSYS/bin:$(cygpath --sysdir)
	MSYSPATH=${MSYSPATH//\/cygdrive/}

	cat >build.sh <<EOF
#!/bin/bash

set -e $xtrace

cd $(cygpath -am .)

exec >>package.log 2>&1

export OSGEO4W_ROOT=$OSGEO4W_ROOT
export OSGEO4W_ROOT_MSYS=$OSGEO4W_ROOT_MSYS
export VCPATH="$VCPATH"
export PATH=$MSYSPATH

pacman --noconfirm -Syu --needed \
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
	mingw-w64-x86_64-pcre \
	mingw-w64-x86_64-fftw \
	mingw-w64-x86_64-lapack \
	mingw-w64-x86_64-readline

cd ../$p

[ -n "$OSGEO4W_SKIP_CLEAN" ] || rm -f mswindows/osgeo4w/configure-stamp

bash.exe $xtrace mswindows/osgeo4w/package.sh
EOF

	taskkill /im gpg-agent.exe /f || true
	if ! cygstart -w $(cygpath -aw msys64/usr/bin/bash.exe) $(cygpath -am build.sh); then
		# re-run if msys terminated before the build even started
		if [ -f ../$p/mswindows/osgeo4w/package.log ] || ! cygstart -w $(cygpath -aw msys64/usr/bin/bash.exe) $(cygpath -am build.sh); then
			cat ../$p/mswindows/osgeo4w/package.log
			exit 1
		fi
	fi
)

cp ../$p/mswindows/osgeo4w/package/$P-$V-1.tar.bz2 $R/$P-$V-$B.tar.bz2
cp ../$p/COPYING $R/$P-$V-$B.txt

cat <<EOF >$R/setup.hint
sdesc: "GRASS GIS ${V%.*}"
ldesc: "Geographic Resources Analysis Support System (GRASS GIS ${V%.*})"
category: Desktop
requires: liblas $RUNTIMEDEPENDS avce00 gpsbabel proj python3-gdal python3-matplotlib libpng libtiff python3-wxpython python3-pillow python3-pip python3-ply python3-pyopengl python3-psycopg2 python3-six zstd python3-pywin32 gs netcdf wxwidgets grass8
maintainer: $MAINTAINER
EOF

mkdir -p $OSGEO4W_REP/x86_64/release/grass{7,8}

cat <<EOF >$OSGEO4W_REP/x86_64/release/grass7/setup.hint
sdesc: "GRASS GIS (transitional package)"
ldesc: "Geographic Resources Analysis Support System (transitional package)"
category: _obsolete
requires: grass
maintainer: $MAINTAINER
external-source: grass
EOF

cat <<EOF >$OSGEO4W_REP/x86_64/release/grass8/setup.hint
sdesc: "GRASS GIS (transitional package)"
ldesc: "Geographic Resources Analysis Support System (transitional package)"
category: _obsolete
requires: grass
maintainer: $MAINTAINER
external-source: grass
EOF

appendversions $R/setup.hint

d=$(mktemp -d)
tar -C $d -cjf $OSGEO4W_REP/x86_64/release/grass8/grass8-99-1.tar.bz2 .
tar -C $d -cjf $OSGEO4W_REP/x86_64/release/grass7/grass7-99-1.tar.bz2 .
rmdir $d

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh osgeo4w/patch

endlog
