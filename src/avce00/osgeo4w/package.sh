export P=avce00
export V=2.0.0
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none
export PACKAGES="avce00"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget http://avce00.maptools.org/dl/$P-$V.tar.gz
[ -f ../makefile.vc ] || tar -C .. -xzf  $P-$V.tar.gz

vsenv

cd ../$P-$V

nmake /f makefile.vc

cd ../osgeo4w

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "The AVCE00 commandline utilities for Arc/Info E00 conversion"
ldesc: "The AVCE00 commandline utilities for Arc/Info E00 conversion"
category: Commandline_Utilities
requires: msvcrt2019
maintainer: $MAINTAINER
EOF

cat <<EOF >$R/$P-$V-$B.txt
 Copyright (c) 1999-2005, Daniel Morissette

 Permission is hereby granted, free of charge, to any person obtaining a
 copy of this software and associated documentation files (the "Software"),
 to deal in the Software without restriction, including without limitation
 the rights to use, copy, modify, merge, publish, distribute, sublicense,
 and/or sell copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included
 in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
 THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.
EOF

tar -C ../$P-$V -cjf $R/$P-$V-$B.tar.bz2 \
	--xform "s,^,bin/," \
	avcexport.exe \
	avcimport.exe \
	avcdelete.exe

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
