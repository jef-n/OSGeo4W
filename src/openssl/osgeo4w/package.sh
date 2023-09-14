export P=openssl
export V=1.1.1w
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none

# perl also used in libpq and qt5
SBPERL=5.32.0.1
NASM=2.15.05

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget https://www.openssl.org/source/$P-$V.tar.gz
[ -d ../$P-$V ] || tar -C .. -xzf  $P-$V.tar.gz

if ! [ -d nasm-$NASM ]; then
	wget -c https://www.nasm.us/pub/nasm/releasebuilds/$NASM/win64/nasm-$NASM-win64.zip
	unzip nasm-$NASM-win64.zip
fi

if ! [ -d perl ]; then
	wget -c http://strawberryperl.com/download/$SBPERL/strawberry-perl-$SBPERL-64bit-portable.zip
	mkdir perl
	cd perl
	unzip ../strawberry-perl-$SBPERL-64bit-portable.zip
	cd ..
fi

vs2019env

(
	fetchenv perl/portableshell.bat /SETENV
	export PATH=$PATH:$(cygpath -a nasm-$NASM)

	cd ../$P-$V

	if ! [ -f built ]; then
		perl Configure VC-WIN64A --prefix=$(cygpath -aw ../osgeo4w/install) --openssldir=$(cygpath -aw ../osgeo4w/install/apps/openssl)

		nmake clean
		nmake
		nmake test
		nmake install

		cd ../osgeo4w

		touch built
	fi
)

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel $R/$P-doc install/etc/postinstall install/etc/ini install/apps/$P/certs

cat <<EOF >install/etc/postinstall/$P.bat
dllupdate -oite -copy -reboot "%OSGEO4W_ROOT%\\bin\\libcrypto-1_1-x64.dll"
dllupdate -oite -copy -reboot "%OSGEO4W_ROOT%\\bin\\libssl-1_1-x64.dll"
if exist "%OSGEO4W_ROOT%\\apps\\Python39\\DLLs" (
	copy "%OSGEO4W_ROOT%\\bin\\libcrypto-1_1-x64.dll" "%OSGEO4W_ROOT%\\apps\\Python39\\DLLs\\libcrypto-1_1.dll"
	copy "%OSGEO4W_ROOT%\\bin\\libssl-1_1-x64.dll" "%OSGEO4W_ROOT%\\apps\\Python39\\DLLs\\libssl-1_1.dll"
)
exit /b 0
EOF

cat <<EOF >install/etc/ini/$P.bat
set OPENSSL_ENGINES=%OSGEO4W_ROOT%\\lib\\engines-1_1
set SSL_CERT_FILE=%OSGEO4W_ROOT%\\bin\\curl-ca-bundle.crt
set SSL_CERT_DIR=%OSGEO4W_ROOT%\\apps\\$P\\certs
EOF

cat <<EOF >$R/setup.hint
sdesc: "OpenSSL Cryptography (Runtime)"
ldesc: "OpenSSL Cryptography (Runtime)"
category: Libs
requires: base msvcrt2019 curl-ca-bundle
maintainer: $MAINTAINER
EOF

cp ../$P-$V/LICENSE $R/$P-$V-$B.txt

tar -C install -cjf $R/$P-$V-$B.tar.bz2 \
	apps/openssl/certs \
	bin/libcrypto-1_1-x64.dll \
	bin/libssl-1_1-x64.dll \
	lib/engines-1_1/capi.dll \
	lib/engines-1_1/padlock.dll \
	etc/postinstall/$P.bat \
	etc/ini/$P.bat

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 \
	osgeo4w/package.sh

cp ../$P-$V/LICENSE $R/$P-devel/$P-devel-$V-$B.txt

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "OpenSSL Cryptography (Development)"
ldesc: "OpenSSL Cryptography (Development)"
category: Libs
requires: $P
external-source: $P
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	--exclude "apps/openssl/certs" \
	apps/openssl \
	bin/c_rehash.pl \
	bin/openssl.exe \
	include/openssl \
	lib/libcrypto.lib \
	lib/libssl.lib \
	bin/libcrypto-1_1-x64.pdb \
	bin/libssl-1_1-x64.pdb \
	bin/openssl.pdb

cat <<EOF >$R/$P-doc/setup.hint
sdesc: "OpenSSL Cryptography (Documentation)"
ldesc: "OpenSSL Cryptography (Documentation)"
category: Libs
requires: $P
external-source: $P
maintainer: $MAINTAINER
EOF

tar -C install -cjf $R/$P-doc/$P-doc-$V-$B.tar.bz2 \
	--xform s,^html,apps/$P/html, \
	html

cp ../$P-$V/LICENSE $R/$P-doc/$P-doc-$V-$B.txt

endlog
