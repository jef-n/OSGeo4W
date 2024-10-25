export P=python3-pdal-plugins
export V=1.6.2
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-devel python3-numpy pdal-devel"
export PACKAGES="python3-pdal-plugins"

source ../../../scripts/build-helpers

startlog

cd ..

if [ -d pdal ]; then
	cd pdal
	git fetch
else
	git clone https://github.com/PDAL/python-plugins pdal
	cd pdal
fi

git checkout $V

cd $OSGEO4W_PWD

fetchenv osgeo4w/bin/o4w_env.bat

vsenv
cmakeenv
ninjaenv

pip3 install scikit_build

cat <<EOF >pip.env
EOF

export INCLUDE="$(cygpath -am osgeo4w/include);\$INCLUDE"
export LIB="$(cygpath -am osgeo4w/lib);\$LIB"

cd ../pdal

pip3 install .

export R=$OSGEO4W_REP/x86_64/release/python3/$P
mkdir -p $R/$P

cat <<EOF >$R/setup.hint
sdesc: "PDAL Python plugins plugin"
ldesc: "PDAL Python plugins allow you to process data with PDAL into Numpy arrays. They support embedding Python in PDAL pipelines with the readers.numpy and filters.python stages."
category: Commandline_Utilities
requires: python3-core pdal-libs
category: Libs
requires: msvcrt2019
maintainer: $MAINTAINER
EOF

tar -C ../osgeo4w -cjf $R/$P-$V-$B.tar.bz2 \
	--xform "s,osgeo4w/apps/$PYTHON/Lib/site-packages/bin/,apps/pdal/plugins/," \
	osgeo4w/apps/$PYTHON/Lib/site-packages/bin/libpdal_plugin_filter_python.dll \
	osgeo4w/apps/$PYTHON/Lib/site-packages/bin/libpdal_plugin_reader_numpy.dll

cp ../pdal/LICENSE $R/$P-$V-$B.txt

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
