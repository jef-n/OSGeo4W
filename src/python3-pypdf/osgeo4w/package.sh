export P=python3-pypdf
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-typing-extensions"
export PACKAGES="python3-pypdf python3-pypdf2"

source ../../../scripts/build-helpers

startlog

PACKAGES=$P packagewheel

p=${P}2

export R=$OSGEO4W_REP/x86_64/release/python3/$p
mkdir -p $R

cat <<EOF >$R/setup.hint
sdesc: "A pure-python PDF library capable of splitting, merging, cropping, and transforming PDF files (transitional package)"
ldesc: "A pure-python PDF library capable of splitting, merging, cropping, and transforming PDF files (transitional package)"
category: _obsolete
requires: $P
maintainer: $MAINTAINER
external-source: $P
EOF

d=$(mktemp -d)
tar -C $d -cjf $R/$p-99-1.tar.bz2 .
rmdir $d

endlog
