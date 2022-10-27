export P=grass-dev
export V=tbd
export B=tbd
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="gdal-devel proj-devel geos-devel netcdf-devel libjpeg-turbo-devel libpng-devel libpq-devel libtiff-devel sqlite3-devel zstd-devel python3-ply python3-core python3-six python3-pywin32 python3-wxpython wxwidgets-devel liblas-devel"

REPO=https://github.com/OSGeo/grass.git

source ../../../scripts/build-helpers

set -o | grep -s "xtrace[	 ]*on" && xtrace=-x || true

startlog

if [ -d ../grass ]; then
	cd ../grass

	if [ -z "$OSGEO4W_SKIP_CLEAN" ]; then
		git clean -f
		git reset --hard
		git pull
	fi

	cd ../osgeo4w
else
	git clone $REPO --branch main --single-branch ../grass
	git config core.filemode false
	unset OSGEO4W_SKIP_CLEAN
fi

if [ -z "$OSGEO4W_SKIP_CLEAN" ]; then
	patch -p1 -d ../grass --dry-run <patch
	patch -p1 -d ../grass <patch
fi

SHA=$(cd ../grass; git log -n1 --pretty=%h)

availablepackageversions $P
# Version: $GRASSVER-$BUILD-$SHA-$BINARY

exec 3<../grass/include/VERSION
read major <&3
read minor <&3
V=$major.$minor

build=1
if [[ "$version_curr" =~ ^[^-]*-[^-]*-[^-]*$ ]]; then
	v=$version_curr
	version=${v%%-*}
	v=${v#*-}

	build=${v%%-*}
	v=${v#*-}
	sha=${v%%-*}

	if [ "$SHA" = "$sha" -a -z "$OSGEO4W_FORCE_REBUILD" ]; then
		echo "$SHA already built."
		endlog
		exit 0
	fi

	if [ "$V" = "$version" ]; then
		(( build++ )) || true
	fi
fi

V=$V-$build-$SHA
nextbinary

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R

if [ -f $R/$P-$V-$B-src.tar.bz2 ]; then
	echo "$R/$P-$V-$B-src.tar.bz2 already exists - skipping"
	exit 1
fi

msysarch=msys2-base-x86_64-20210604.tar.xz

[ -f $msysarch ] || wget http://repo.msys2.org/distrib/x86_64/$msysarch
[ -d msys64 ] || tar xJf $msysarch

(
	set -e

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
	cmd="pacman --noconfirm -Sy --needed \
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

	cd ../grass

	PACKAGE_POSTFIX=-dev cmd.exe /c "$(cygpath -aw $OSGEO4W_PWD/msys64/usr/bin/bash) $xtrace mswindows/osgeo4w/package.sh"
)

mv ../grass/mswindows/osgeo4w/package/$P-$major.$minor.dev-1.tar.bz2 $R/$P-$V-$B.tar.bz2
cp ../grass/COPYING $R/$P-$V-$B.txt

cat <<EOF >$R/setup.hint
sdesc: "GRASS GIS ${V%.*} nightly"
ldesc: "Geographic Resources Analysis Support System (GRASS GIS ${V%.*} nightly)"
category: Desktop
requires: liblas $RUNTIMEDEPENDS avce00 gpsbabel proj python3-gdal python3-matplotlib libtiff python3-wxpython python3-pillow python3-pip python3-ply python3-pyopengl python3-psycopg2-binary python3-six zstd python3-pywin32 gs netcdf wxwidgets
maintainer: $MAINTAINER
EOF

appendversions $R/setup.hint

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh osgeo4w/patch

endlog
