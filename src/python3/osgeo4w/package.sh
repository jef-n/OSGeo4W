export P=python3
export V=3.12.4
export B="next $P-core"
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="openssl-devel bzip2-devel xz-devel zlib-devel sqlite3-devel"
export PACKAGES="python3-core python3-devel python3-help python3-tcltk python3-test python3-tools"

source ../../../scripts/build-helpers

startlog

M=${V%%.*}
VM=${V%.*}
MM=${VM//./}
MMM=${V//./}

[ -f Python-$V.tar.xz ] || wget https://www.python.org/ftp/python/$V/Python-$V.tar.xz
[ -d ../Python-$V ] || tar -C .. -xJf Python-$V.tar.xz
[ -f ../Python-$V/patched ] || {
	patch --dry-run -p1 -d ../Python-$V <patch
	patch -p1 -d ../Python-$V <patch >../Python-$V/patched
}

(
	set -e

	cd ../Python-$V

	fetchenv ../osgeo4w/osgeo4w/bin/o4w_env.bat

	vsenv

	# fetch externals - but skip some
	mkdir -p externals/{bzip2-1.0.8,sqlite-3.43.1.0,xz-5.2.5,zlib-1.3.1,openssl-3.0.13,openssl-bin-3.0.13}
	export LANG=C LC_ALL=C PATH=$(cygpath --sysdir)/WindowsPowerShell/v1.0:$PATH
	cmd /c Tools\\msi\\get_externals.bat

	export PATH=$(cygpath -au externals/pythonx86/tools/Scripts):$(cygpath -au externals/pythonx86/tools):$PATH

	[ -f osgeo4w.built ] || {
		cmd /c Doc\\make.bat htmlhelp
		[ -f Doc/build/htmlhelp/python$MMM.chm ]
		cmd /c Tools\\msi\\buildrelease.bat -x64 --skip-msi --skip-nuget --skip-zip
		touch osgeo4w.built
	}
)


PREFIX=apps/Python$MM/

exetmpl() {
	local i=$1
	local pkg=$2
	local b=$(basename $i)
	local t=${PREFIX}Scripts/$b

	echo -e "textreplace -std -t ${t///\\}\r" >>$pkg-postinstall.bat
	echo -e "del ${t//\//\\\\}\r" >>$pkg-preremove.bat

	[ -s $i ]
	perl -pe "s#${PY//\\/\\\\}#\@osgeo4w\@\\\\apps\\\\Python$MM\\\\python.exe#i" $i >$b.tmpl
	chmod a+rx $b.tmpl
}

export S=../Python-$V R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R

rm -rf install

mkdir -p install/{bin,${PREFIX%/}/{DLLs,Tools}}

cp $S/LICENSE						install/${PREFIX}LICENSE.txt
cp -a $S/Tools/{scripts,i18n}		                install/${PREFIX}Tools/
cp $S/{PC/icons/py{,c,d}.ico,PCbuild/amd64/*.{dll,pyd}}	install/${PREFIX}DLLs/
cp -a $S/Lib						install/${PREFIX}Lib
cp $S/PCbuild/amd64/python{$M,$MM}.dll			install/${PREFIX}
cp -a $S/externals/tcltk-8.6.13.0/amd64/lib		install/${PREFIX}tcl
cp $S/PCbuild/amd64/python{$M,$MM}.dll			install/bin
for a in "" "w"; do
	for b in "" $M; do
		cp $S/PCbuild/amd64/python$a.exe install/${PREFIX}python$a$b.exe
		cp $S/PCbuild/amd64/python$a.exe install/bin/python$a$b.exe
	done
	cp $S/PCbuild/amd64/venv${a}launcher.exe install/${PREFIX}Lib/venv/scripts/nt/python$a.exe
done

PY=$(cygpath -aw install/${PREFIX}python.exe)

for p in core help devel test tcltk tools; do
	mkdir -p $R/$P-$p
	cp $S/LICENSE $R/$P-$p/$P-$p-$V-$B.txt
done


cat <<EOF >$R/$P-core/setup.hint
sdesc: "Python core interpreter and runtime"
ldesc: "Python core interpreter and runtime"
maintainer: $MAINTAINER
category: Commandline_Utilities
requires: base msvcrt2019 sqlite3 openssl api-ms-win-core-path-HACK
external-source: $P
EOF

cat <<EOF >tcltk.lst
install/${PREFIX}DLLs/_tkinter.pyd
install/${PREFIX}DLLs/tcl86t.dll
install/${PREFIX}DLLs/tk86t.dll
install/${PREFIX}Lib/idlelib
install/${PREFIX}tcl
EOF

cat <<EOF >test.lst
install/${PREFIX}DLLs/_ctypes_test.pyd
install/${PREFIX}DLLs/_testbuffer.pyd
install/${PREFIX}DLLs/_testcapi.pyd
install/${PREFIX}DLLs/_testconsole.pyd
install/${PREFIX}DLLs/_testimportmultiple.pyd
install/${PREFIX}DLLs/_testmultiphase.pyd
install/${PREFIX}Lib/idlelib/idle_test
install/${PREFIX}Lib/test
install/${PREFIX}tcl/tcl8/8.5/tcltest-2.5.5.tm
install/${PREFIX}Tools/scripts/run_tests.py
EOF

cat <<EOF >tools.lst
install/Tools
EOF

cat <<EOF >preremove-cached.py
import importlib.util
import gzip
import os
import sys

cachedirs = {}
with gzip.open("{}/etc/setup/{}.lst.gz".format(os.environ['OSGEO4W_ROOT'], sys.argv[1])) as f:
    for py in f:
        py = py.decode("utf-8").strip()
        if py.endswith(".py"):
            try:
                pyc = importlib.util.cache_from_source(py)
                os.remove(pyc)
                print("Removed {}".format(pyc))
                cachedirs[ os.path.dirname(pyc) ] = 1
            except:
                pass

for cachedir in sorted(cachedirs.keys(), reverse=True):
    try:
        os.rmdir(cachedir)
        print("Removed directory {}".format(cachedir))
    except:
        pass
EOF

cat <<EOF >sitecustomize.py
import os
import sys

paths = os.environ['PATH'].split(";")

if 'OSGEO4W_ROOT' not in os.environ:
    o4w = os.path.normpath(
        os.path.join(
            os.path.dirname(os.path.realpath(__file__)),
            "..", "..", "..", "..")
    )
    os.environ['OSGEO4W_ROOT'] = o4w
    for p in [
        "bin",
        "apps\\\\qt5\\\\bin",
        f"apps\\\\Python$MM",
        f"apps\\\\Python$MM\\\\Scripts"
    ]:
        p = os.path.join(o4w, p)
        if os.path.exists(p):
            paths.insert(0, p)

for p in paths:
    if os.path.exists(p):
        os.add_dll_directory(p)
EOF

#
# core
#

cat <<EOF >ini.bat
SET PYTHONHOME=%OSGEO4W_ROOT%\\apps\\Python$MM
SET PYTHONPATH=
SET PYTHONUTF8=1
PATH %OSGEO4W_ROOT%\\apps\\Python$MM\Scripts;%PATH%
EOF

cat <<EOF >core-preremove.bat
python -B "%OSGEO4W_ROOT%\\apps\\Python$MM\\Scripts\\preremove-cached.py" $P-core
EOF

tar -cjf $R/$P-core/$P-core-$V-$B.tar.bz2 \
	--xform "s,preremove-cached.py,${PREFIX}Scripts/preremove-cached.py," \
	--xform "s,sitecustomize.py,${PREFIX}Lib/site-packages/sitecustomize.py," \
	--xform "s,core-postinstall.bat,etc/postinstall/$P-core.bat," \
	--xform "s,core-preremove.bat,etc/preremove/$P-core.bat," \
	--xform "s,ini.bat,etc/ini/$P.bat," \
	--xform "s,^install/,," \
	--exclude "install/apps/$PYTHON/DLLs/libcrypto-3.dll" \
	--exclude "install/apps/$PYTHON/DLLs/libssl-3.dll" \
	--exclude "install/apps/$PYTHON/DLLs/vcruntime140.dll" \
	--exclude "install/apps/$PYTHON/DLLs/vcruntime140_1.dll" \
	--exclude __pycache__ \
	--exclude-from tcltk.lst \
	--exclude-from test.lst \
	--exclude-from tools.lst \
	preremove-cached.py \
	sitecustomize.py \
	core-preremove.bat \
	ini.bat \
	install/bin/python{$M,$MM}.dll \
	install/bin/python{,w,$M,w$M}.exe \
	install/${PREFIX}DLLs \
	install/${PREFIX}Lib \
	install/${PREFIX}LICENSE.txt \
	install/${PREFIX}python{$M,$MM}.dll \
	install/${PREFIX}python{,w,$M,w$M}.exe

#
# help
#

cat <<EOF >$R/$P-help/setup.hint
sdesc: "Python documentation in a Windows compiled help file"
ldesc: "Python documentation in a Windows compiled help file"
maintainer: $MAINTAINER
category: Commandline_Utilities
requires: $P-core
external-source: $P
EOF

tar -cjf $R/$P-help/$P-help-$V-$B.tar.bz2 \
	--xform "s,^Python-$V/Doc/build/htmlhelp/,${PREFIX}Doc/," \
	$S/Doc/build/htmlhelp/NEWS \
	$S/Doc/build/htmlhelp/python$MMM.chm

#
# devel
#


cat <<EOF >$R/$P-devel/setup.hint
sdesc: "Python library and header files"
ldesc: "Python library and header files"
maintainer: $MAINTAINER
category: Libs
requires: $P-core
external-source: $P
EOF

tar -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	--xform "s,^Python-$V/PCbuild/amd64/,${PREFIX}libs/," \
	--xform "s,^Python-$V/Include,${PREFIX}include," \
	--xform "s,^Python-$V/PC/,${PREFIX}include/," \
	$S/Include \
	$S/PCbuild/amd64/python{$M,$MM}.lib \
	$S/PCbuild/amd64/_tkinter.lib \
	$S/PC/pyconfig.h

#
# test
#

cat <<EOF >$R/$P-test/setup.hint
sdesc: "Python self tests"
ldesc: "Python self tests"
maintainer: $MAINTAINER
category: Libs
requires: $P-core
external-source: $P
EOF

cat <<EOF >test-preremove.bat
python -B "%OSGEO4W_ROOT%\\apps\\Python$MM\\Scripts\\preremove-cached.py" $P-test
EOF

tar -cjf $R/$P-test/$P-test-$V-$B.tar.bz2 \
	--xform "s,test-preremove.bat,etc/preremove/$P-test.bat," \
	--xform "s,^install/,," \
	--exclude __pycache__ \
	-T test.lst \
	test-preremove.bat

#
# tcltk & idle
#

cat <<EOF >$R/$P-tcltk/setup.hint
sdesc: "Python Tkinter and IDLE"
ldesc: "Python Tkinter and IDLE"
maintainer: $MAINTAINER
category: Commandline_Utilities
requires: $P-core
external-source: $P
EOF

cat <<EOF >tcltk-preremove.bat
python -B "%OSGEO4W_ROOT%\\apps\\Python$MM\\Scripts\\preremove-cached.py" $P-tcltk
EOF

tar -cjf $R/$P-tcltk/$P-tcltk-$V-$B.tar.bz2 \
	--xform "s,tcltk-preremove.bat,etc/preremove/$P-tcltk.bat," \
	--xform "s,^install/,," \
	--exclude __pycache__ \
	--exclude-from test.lst \
	-T tcltk.lst \
	tcltk-preremove.bat

#
# tools
#

cat <<EOF >$R/$P-tools/setup.hint
sdesc: "Python Tools"
ldesc: "Python Tools"
maintainer: $MAINTAINER
category: Commandline_Utilities
requires: $P-core
external-source: $P
EOF

cat <<EOF >tools-preremove.bat
python -B "%OSGEO4W_ROOT%\\apps\\Python$MM\\Scripts\\preremove-cached.py" $P-tools
EOF

tar -cjf $R/$P-tools/$P-tools-$V-$B.tar.bz2 \
	--xform "s,tools-preremove.bat,etc/preremove/$P-tools.bat," \
	--xform "s,^install/,," \
	--exclude __pycache__ \
	--exclude-from tcltk.lst \
	--exclude-from test.lst \
	install/${PREFIX}Tools \
	tools-preremove.bat

if [ "$OSGEO4W_BUILDMODE" = "test" ]; then
	v=version_test
else
	v=version_curr
fi

eval $v=$V appendversions $R/$P-core/setup.hint
eval $v=$V appendversions $R/$P-help/setup.hint
eval $v=$V appendversions $R/$P-devel/setup.hint
eval $v=$V appendversions $R/$P-test/setup.hint
eval $v=$V appendversions $R/$P-tcltk/setup.hint
eval $v=$V appendversions $R/$P-tools/setup.hint

tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

#
# check
#

find install -type f | sed -e '/\.pyc$/d; s#^install/##;' >/tmp/$P-installed.lst

(
	tar -tjf $R/$P-core/$P-core-$V-$B.tar.bz2 | sed -e "s/$/:core/"
	tar -tjf $R/$P-help/$P-help-$V-$B.tar.bz2 | sed -e "s/$/:help/"
	tar -tjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 | sed -e "s/$/:devel/"
	tar -tjf $R/$P-test/$P-test-$V-$B.tar.bz2 | sed -e "s/$/:test/"
	tar -tjf $R/$P-tcltk/$P-tcltk-$V-$B.tar.bz2 | sed -e "s/$/:tcltk/"
	tar -tjf $R/$P-tools/$P-tools-$V-$B.tar.bz2 | sed -e "s/$/:tools/"
) | egrep -v '(/|\.pyc):' | sort >/tmp/$P-packaged.lst

cut -d: -f1 /tmp/$P-packaged.lst | sort | uniq -d >/tmp/$P-dupes.lst
if [ -s /tmp/$P-dupes.lst ]; then
	echo DUPES:
	grep -f <(sed -e 's/^/^/; s/$/:/;' /tmp/$P-dupes.lst) /tmp/$P-packaged.lst | sort
fi

# whitelist processed files
# OpenSSL shipped in openssl
# sqlite3 in sqlite3
# python*.dll moved to bin
# msvcrt runtime in msvcrt2019
if egrep -v \
	-f <(sed -e 's/:.*$//; /\.pyc$/d; s#^'$PREFIX'##; s/[+.$]/\\&/g; s/(dev)/\\(dev\\)/; s/$/$/;' /tmp/$P-packaged.lst) \
	/tmp/$P-installed.lst |
	egrep -v "_d\.(pyd|dll)$" |
	fgrep -v -x -f <(cat <<EOF
${PREFIX}DLLs/libcrypto-3.dll
${PREFIX}DLLs/libssl-3.dll
${PREFIX}DLLs/sqlite3.dll
${PREFIX}DLLs/vcruntime140.dll
${PREFIX}DLLs/vcruntime140_1.dll
${PREFIX}python$M.dll
${PREFIX}python$MM.dll
${PREFIX}python.exe
${PREFIX}pythonw.exe
EOF
) >/tmp/$P-unpackaged.lst; then
	echo UNPACKAGED:
	cat /tmp/$P-unpackaged.lst
	false
fi

# whitelist generate files
# moved python.exe
# preremoved-cached.py
# dlls in bin
# postinstall/preremove scripts
if egrep -v \
	-f <(sed -e '/\.pyc$/d; s#^#^('$PREFIX'|)#; s/[+.$]/\\&/g; s/(dev)/\\(dev\\)/; s/$/$/;' /tmp/$P-installed.lst) \
	<(grep -v ":devel$" /tmp/$P-packaged.lst | cut -d: -f1) |
	fgrep -v -x -f <(cat <<EOF
${PREFIX}python$M.exe
${PREFIX}pythonw$M.exe
${PREFIX}Scripts/preremove-cached.py
${PREFIX}Lib/site-packages/sitecustomize.py
${PREFIX}Doc/NEWS
${PREFIX}Doc/python$MMM.chm
bin/python$M.dll
bin/python$M.exe
bin/python$MM.dll
bin/pythonw$M.exe
etc/ini/$P.bat
etc/preremove/$P-core.bat
etc/preremove/$P-tcltk.bat
etc/preremove/$P-test.bat
etc/preremove/$P-tools.bat
EOF
) >/tmp/$P-generated.lst; then
	echo GENERATED:
	cat /tmp/$P-generated.lst
	false
fi

endlog
