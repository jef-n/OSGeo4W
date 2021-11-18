#!/bin/bash

set -e

cert=$PWD/src/setup/osgeo4w/OSGeo_DigiCert_Signing_Cert

if [ -r "$cert.p12" -a -r "$cert.pass" ]; then
	sign="-signwith=$cert.p12 -signpass=$(<$cert.pass)"
fi

for i in ${PKGS:-qgis qgis-ltr}; do
	releasename=$(sed -ne 's/^set(RELEASE_NAME "\(.*\)").*$/\1/ip' src/$i/qgis/CMakeLists.txt)

	perl scripts/createmsi.pl \
		$sign \
		-verbose \
		-releasename="$releasename" \
		-shortname="$i" \
		-banner=$PWD/src/$i/osgeo4w/qgis_msibanner.bmp \
		-background=$PWD/src/$i/osgeo4w/qgis_msiinstaller.bmp \
		-arpicon=$PWD/src/$i/osgeo4w/qgis.ico \
		$i-full
done
