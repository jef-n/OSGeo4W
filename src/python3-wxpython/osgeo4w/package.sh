export P=python3-wxpython
export V=4.1.0
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="base python3-core python3-setuptools python3-devel wxwidgets-devel"

source ../../../scripts/build-helpers

startlog

[ -f wxPython-$V.tar.gz ] || wget https://files.pythonhosted.org/packages/cb/4f/1e21d3c079c973ba862a18f3be73c2bbe2e6bc25c96d94df605b5cbb494d/wxPython-$V.tar.gz
[ -f ../setup.py ] || tar -C .. -xzf wxPython-$V.tar.gz --xform "s,^wxPython-$V,.,"
[ -f patched ] || {
	patch -d .. -p1 --dry-run <wx.diff
	patch -d .. -p1 <wx.diff
	touch patched
}

(
	fetchenv osgeo4w/bin/o4w_env.bat
	vs2019env

	type cl.exe

	cd ..

	export INCLUDE="$(cygpath -aw osgeo4w/osgeo4w/lib/vc_x64_dll/mswu);$(cygpath -aw osgeo4w/osgeo4w/include);$INCLUDE"
	export LIB="$(cygpath -aw osgeo4w/osgeo4w/lib/vc_x64_dll);$LIB"
	python3 build.py build_py --release --x64 --use_syswx --extra_waf='--msvc_version="msvc 16.7"'

	python3 build.py bdist_wheel

	wheel=$(cygpath -aw dist/*.whl) addsrcfiles=osgeo4w/wx.diff packagewheel
)

endlog
