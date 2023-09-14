export P=imposm3
export V=0.11.1
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=base

export GO_MSI=go1.21.1.windows-amd64.msi

source ../../../scripts/build-helpers

startlog

msysarch=msys2-base-x86_64-20230526.tar.xz

[ -f $msysarch ] || wget http://repo.msys2.org/distrib/x86_64/$msysarch
[ -d msys64 ] || tar xJf $msysarch

(
	set -e

	fetchenv osgeo4w/bin/o4w_env.bat
	export OSGEO4W_ROOT_MSYS="${OSGEO4W_ROOT//\\/\/}"
	export OSGEO4W_ROOT_MSYS="/${OSGEO4W_ROOT_MSYS:0:1}/${OSGEO4W_ROOT_MSYS:3}"

	export CGO_LDFLAGS="-lstdc++"

	export PATH="$(cygpath -a msys64/usr/bin):$PATH"

	[ -f msys64/msys2.init ] || {
		cmd.exe /c bash pacman-key --init
		cmd.exe /c bash pacman-key --populate msys2
		cmd.exe /c bash /etc/profile
		touch msys64/msys2.init
	}

	cmd.exe /c pacman --noconfirm -Syuu --needed

	cmd="pacman --noconfirm -Sy --needed mingw-w64-x86_64-gcc mingw-w64-x86_64-leveldb"
	cmd.exe /c $cmd || cmd.exe /c $cmd || cmd.exe /c $cmd

	export PATH="$PWD/msys64/mingw64/bin:$PATH:$PWD/go/Go/bin"
	export GOPATH=$(cygpath -aw go/Go)

	if ! type go >/dev/null || ! go version; then
		[ -f $GO_MSI ] || wget -q -c -O $GO_MSI https://go.dev/dl/$GO_MSI
		if ! msiexec "/l*v" go.log /a $GO_MSI "TARGETDIR=$(cygpath -aw go)" /qb; then
			iconv -f UTF-16 -t UTF-8 go.log
			false
		fi
		go version
	fi

	mkdir -p ../Go
	export GOPATH=$(cygpath -aw ../Go)

	cd $GOPATH
	go install github.com/omniscale/imposm3/cmd/imposm@v$V
)

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P

cat <<EOF >$R/setup.hint
sdesc: "Imposm is an importer for OpenStreetMap data."
ldesc: "Imposm is an importer for OpenStreetMap data. It reads PBF files and
imports the data into PostgreSQL/PostGIS. It can also automatically update the
database with the latest changes from OSM."
category: Commandline_Utilities
requires: geos
maintainer: $MAINTAINER
EOF

p=${P%3}

cat <<EOF | tee $p.cmd >$P.cmd
@echo off
call "%~dp0\\o4w_env.bat"
"%OSGEO4W_ROOT%\\apps\\$P\\$p.exe" %*
EOF

tar -cjf $R/$P-$V-$B.tar.bz2 \
	--xform "s,Go/bin/imposm.exe,apps/$P/imposm.exe," \
	--xform "s,msys64/mingw64/bin/,apps/$P/," \
	--xform "s,$P.cmd,bin/$P.cmd," \
	--xform "s,$p.cmd,bin/$p.cmd," \
	$P.cmd \
	$p.cmd \
	../Go/bin/imposm.exe \
	msys64/mingw64/bin/libwinpthread-1.dll \
	msys64/mingw64/bin/libstdc++-6.dll \
	msys64/mingw64/bin/libgcc_s_seh-1.dll \
	msys64/mingw64/bin/libleveldb.dll \
	msys64/mingw64/bin/libgeos.dll \
	msys64/mingw64/bin/libgeos_c.dll

cp ../Go/pkg/mod/github.com/omniscale/$P@v$V/LICENSE $R/$P-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
