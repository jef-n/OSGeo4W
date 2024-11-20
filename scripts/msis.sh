#!/bin/bash

set -e

cert=$PWD/src/setup/osgeo4w/OSGeo_DigiCert_Signing_Cert
: ${mirror:=https://download.osgeo.org/osgeo4w/v2}

sign=
if [ -r "$cert.p12" -a -r "$cert.pass" ]; then
	[ -z "$CI" ] || echo "::add-mask::$(<$cert.pass)"
	sign="-signwith=$cert.p12 -signpass=$(<$cert.pass)"
fi

for i in ${PKGS:-qgis qgis-ltr}; do
	o=
	if [ -f "src/$i/qgis/CMakeLists.txt" -a src/$i/osgeo4w/qgis_msibanner.bmp -a src/$i/osgeo4w/qgis_msiinstaller.bmp -a src/$i/osgeo4w/qgis.ico ]; then
		o="-releasename=$(sed -ne 's/^set(RELEASE_NAME "\(.*\)").*$/\1/ip' src/$i/qgis/CMakeLists.txt)"
		o="$o -banner=$PWD/src/$i/osgeo4w/qgis_msibanner.bmp"
		o="$o -background=$PWD/src/$i/osgeo4w/qgis_msiinstaller.bmp"
		o="$o -arpicon=$PWD/src/$i/osgeo4w/qgis.ico"
	fi

	[ -z "$CI" ] || echo "::group::Creating MSI for $i"

	eval perl scripts/createmsi.pl \
		$sign \
		$o \
		-verbose \
		-shortname="$i" \
		-mirror=$mirror \
		$i-full

	[ -z "$CI" ] || echo "::endgroup::"
done
