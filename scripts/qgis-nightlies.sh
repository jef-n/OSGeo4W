export OSGEO4W_REP=$GITHUB_WORKSPACE
export OSGEO4W_SKIP_UPLOAD=1
export PATH=/bin:/usr/bin

for p in qgis-dev qgis-rel-dev qgis-ltr-dev; do
	cd $GITHUB_WORKSPACE/src/$p/osgeo4w
	if ! bash package.sh; then
		echo "BUILD $p failed [$?]"
	fi
done

cd $GITHUB_WORKSPACE
scripts/upload.sh
