export P=setup
export V=1.1.2
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none
export PACKAGES="setup"

export ZLIB_VER=1.3.1
export BZIP2_VER=1.0.8

source ../../../scripts/build-helpers

startlog

vsenv
cmakeenv
ninjaenv

[ -f zlib-${ZLIB_VER}.tar.gz ] || wget https://www.zlib.net/zlib-${ZLIB_VER}.tar.gz
[ -d zlib-${ZLIB_VER} ] || tar xzf zlib-${ZLIB_VER}.tar.gz
[ -f bzip2-${BZIP2_VER}.tar.gz ] || wget -O bzip2-${BZIP2_VER}.tar.gz https://sourceware.org/pub/bzip2/bzip2-${BZIP2_VER}.tar.gz
[ -d bzip2-${BZIP2_VER} ] || tar xzf bzip2-${BZIP2_VER}.tar.gz

mkdir -p build install
rm -f install/bin/osgeo4w-setup.exe
cd build

CONF=MinSizeRel

cmake -G Ninja \
	-D CMAKE_BUILD_TYPE=$CONF \
	-D CMAKE_EXE_LINKER_FLAGS="/MANIFEST:NO" \
	-D CMAKE_CXX_FLAGS_${CONF^^}="/O1 /Ob1 /D NDEBUG" \
	-D CMAKE_INSTALL_PREFIX=../install \
	-D ZLIB_SRC=$(cygpath -am ../zlib-${ZLIB_VER}) \
	-D BZIP2_SRC=$(cygpath -am ../bzip2-${BZIP2_VER}) \
	../..

cmake --build .

cd ..

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R

cat <<EOF >$R/setup.hint
sdesc: "OSGeo4W Installer/Updater"
ldesc: "OSGeo4W Installer/Updater"
category: Commandline_Utilities
requires: msvcrt2019 base
maintainer: $MAINTAINER
EOF

mkdir -p install/{bin,etc/{postinstall,preremove}}

cat <<EOF >install/etc/postinstall/$P.bat
for /F "tokens=* USEBACKQ" %%F IN (\`getspecialfolder Documents\`) do set DOCUMENTS=%%F

if not %OSGEO4W_MENU_LINKS%==0 if not exist "%OSGEO4W_STARTMENU%" mkdir "%OSGEO4W_STARTMENU%"
if not %OSGEO4W_MENU_LINKS%==0 xxmklink "%OSGEO4W_STARTMENU%\Setup.lnk" "%OSGEO4W_ROOT%\bin\bgspawn.exe" "\"%OSGEO4W_ROOT%\bin\setup.bat\"" "%DOCUMENTS%" "" 1 "%OSGEO4W_ROOT%\osgeo4w.ico"

if not %OSGEO4W_DESKTOP_LINKS%==0 if not exist "%OSGEO4W_DESKTOP%" mkdir "%OSGEO4W_DESKTOP%"
if not %OSGEO4W_DESKTOP_LINKS%==0 xxmklink "%OSGEO4W_DESKTOP%\OSGeo4W Setup.lnk" "%OSGEO4W_ROOT%\bin\bgspawn.exe" "\"%OSGEO4W_ROOT%\bin\setup.bat\"" "%DOCUMENTS%" "" 1 "%OSGEO4W_ROOT%\osgeo4w.ico"

textreplace -std -t bin\setup.bat
EOF

cat <<EOF >install/etc/preremove/$P.bat
del "%OSGEO4W_STARTMENU%\\Setup.lnk"
del "%OSGEO4W_DESKTOP%\\Setup.lnk"
EOF

cat <<EOF >install/bin/setup.bat.tmpl
@start /B "Running Setup" "@osgeo4w@\\bin\\osgeo4w-setup.exe" -R "@osgeo4w@" %*
EOF

rm -f install/bin/osgeo4w-setup.exe

if [ -f OSGeo_DigiCert_Signing_Cert.p12 -a -f OSGeo_DigiCert_Signing_Cert.pass ]; then
	osslsigncode sign \
		-pkcs12 OSGeo_DigiCert_Signing_Cert.p12 \
		-pass $(<OSGeo_DigiCert_Signing_Cert.pass) \
		-n "OSGeo4W Installer" \
		-h sha256 \
		-i http://osgeo4w.osgeo.org \
		-t http://timestamp.digicert.com \
		-in build/osgeo4w-setup.exe \
		install/bin/osgeo4w-setup.exe

	[ -n "$OSGEO4W_SKIP_UPLOAD" ] || rsync -v install/bin/osgeo4w-setup.exe $MASTER_SCP
else
	cp build/osgeo4w-setup.exe install/bin/osgeo4w-setup.exe
fi

cp install/bin/osgeo4w-setup.exe ../../../scripts

tar -C install -cjf $R/$P-$V-$B.tar.bz2 bin etc

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

cp ../COPYING $R/$P-$V-$B.txt

endlog
