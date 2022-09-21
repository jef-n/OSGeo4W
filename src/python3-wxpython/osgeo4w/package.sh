export P=python3-wxpython
export V=4.2.0
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="base python3-core python3-setuptools python3-wheel python3-devel python3-attrdict wxwidgets-devel"

source ../../../scripts/build-helpers

startlog

[ -f wxPython-$V.tar.gz ] || wget https://files.pythonhosted.org/packages/d9/33/b616c7ed4742be6e0d111ca375b41379607dc7cc7ac7ff6aead7a5a0bf53/wxPython-$V.tar.gz
[ -f ../wxPython-$V/setup.py ] || {
	tar -C .. -xzf wxPython-$V.tar.gz
	rm -f patched
}
[ -f patched ] || {
	patch -d ../wxPython-$V -p1 --dry-run <wx.diff
	patch -d ../wxPython-$V -p1 <wx.diff
	touch patched
}

(
	fetchenv osgeo4w/bin/o4w_env.bat
	vs2019env

	type cl.exe

	cd ../wxPython-$V

	export INCLUDE="$(cygpath -aw ../osgeo4w/osgeo4w/lib/vc_x64_dll/mswu);$(cygpath -aw ../osgeo4w/osgeo4w/include);$INCLUDE"
	export LIB="$(cygpath -aw ../osgeo4w/osgeo4w/lib/vc_x64_dll);$LIB"
	python3 build.py build_py --release --x64 --use_syswx --extra_waf='--msvc_version="msvc 16.11"'

	python3 build.py bdist_wheel

	wheel=$(cygpath -aw dist/*.whl) addsrcfiles=osgeo4w/wx.diff adddepends=wxwidgets packagewheel
)

endlog
