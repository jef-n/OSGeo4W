#!/bin/bash

set -e

cert=src/setup/osgeo4w/OSGeo_DigiCert_Signing_Cert

[ -r "$cert.p12" ]
[ -r "$cert.pass" ]

for i in qgis qgis-ltr; do
	releasename=$(sed -ne 's/^set(RELEASE_NAME "\(.*\)").*$/\1/ip' src/$i/qgis/CMakeLists.txt)

	perl scripts/createmsi.pl \
		-sign-with=$cert.p12 \
		-signpass=$(<$cert.pass) \
		-verbose \
		-releasename="$releasename" \
		-banner=src/$i/osgeo4w/qgis_msibanner.bmp \
		-background=src/$i/osgeo4w/qgis_msiinstaller.bmp \
		$i-full
done
