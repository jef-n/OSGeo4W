export P=transifex-cli
export V=1.6.10
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none
export PACKAGES="transifex-cli"

export GO_MSI=go1.19.2.windows-amd64.msi

source ../../../scripts/build-helpers

startlog

[ -f "$P-$V.tar.gz" ] || curl -JL --output $P-$V.tar.gz https://github.com/${P/-//}/archive/refs/tags/v$V.tar.gz
[ -f ../$P-$V ] || tar -C .. -xzf $P-$V.tar.gz --xform "s,cli-$V,$P-$V,"

(
	set -e

	export PATH="$PATH:$PWD/go/Go/bin"
	export GOPATH=$(cygpath -aw go/Go)

	if ! type go >/dev/null || ! go version; then
		[ -f $GO_MSI ] || wget -q -c -O $GO_MSI https://go.dev/dl/$GO_MSI
		if ! msiexec "/l*v" go.log /a $GO_MSI "TARGETDIR=$(cygpath -aw go)" /qb; then
			iconv -f UTF-16 -t UTF-8 go.log
			false
		fi
		go version
	fi

	export GOPATH=$(cygpath -aw ../Go)

	cd ../$P-$V
	go build -o ../osgeo4w/tx.exe
)

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P

cat <<EOF >$R/setup.hint
sdesc: "transifex command line client."
ldesc: "transifex command line client."
requires: 
category: Commandline_Utilities
maintainer: $MAINTAINER
EOF

tar -cjf $R/$P-$V-$B.tar.bz2 \
	--xform "s,tx.exe,bin/tx.exe," \
	tx.exe

cp ../$P-$V/LICENSE $R/$P-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
