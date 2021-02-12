#!/bin/sh

rm *.bz2

./package.sh

scp setup-*.bz2 frankw@upload.osgeo.org:/osgeo/download/osgeo4w/release/setup
scp setup.exe frankw@upload.osgeo.org:/osgeo/download/osgeo4w/osgeo4w-setup.exe
