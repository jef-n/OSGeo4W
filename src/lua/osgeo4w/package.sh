export P=lua
export V=5.4.7
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none
export PACKAGES="lua lua-devel"

source ../../../scripts/build-helpers

startlog

[ -f $P-$V.tar.gz ] || wget http://www.lua.org/ftp/$P-$V.tar.gz
[ -d ../$P-$V ] || tar -C .. -xzf $P-$V.tar.gz

vsenv

cd ../$P-$V/src

cl /MD /O2 /W3 /c /DLUA_BUILD_AS_DLL *.c
LOBJ=$(ls -1 *.obj | egrep -v "^luac?\.obj$")
link /DLL /IMPLIB:lua.lib /OUT:lua${V%.*}.dll $LOBJ
link /OUT:lua.exe lua.obj lua.lib
lib /OUT:lua-static.lib $LOBJ
link /OUT:luac.exe luac.obj lua-static.lib
./lua.exe -v

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel

cat <<EOF >$R/setup.hint
sdesc: "Lua scripting language (runtime)"
ldesc: "Lua is a powerful, efficient, lightweight, embeddable scripting
language. It supports procedural programming, object-oriented programming,
functional programming, data-driven programming, and data description."
category: Libs
requires: msvcrt2019
maintainer: $MAINTAINER
EOF

tar -cjf $R/$P-$V-$B.tar.bz2 \
	--xform "s,^,bin/," \
	lua${V%.*}.dll \
	lua.exe \
	luac.exe

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "Lua scripting language (development)"
ldesc: "Lua is a powerful, efficient, lightweight, embeddable scripting
language. It supports procedural programming, object-oriented programming,
functional programming, data-driven programming, and data description."
category: Libs
requires: $P
maintainer: $MAINTAINER
external-source: $P
EOF

tar -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	--xform "s,^\\(.*\\.h\\)$,include/lua${V%.*}/\\1," \
	--xform "s,^\\(.*\\.hpp\\)$,include/lua${V%.*}/\\1," \
	--xform "s,^\\(.*\\.lib\\)$,lib/\\1," \
	*.h \
	*.hpp \
	*.lib

cat <<EOF | tee -a $R/$P-$V-$B.txt >$R/$P-devel/$P-devel-$P-$V-$B.txt
Copyright © 1994–2022 Lua.org, PUC-Rio.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

tar -C ../.. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
