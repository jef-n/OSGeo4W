export P=python3-wxpython
export V=4.2.5
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="base python3-core python3-setuptools python3-wheel python3-devel python3-pip python3-attrdict3 wxwidgets-devel python3-numpy python3-pillow python3-six"
export PACKAGES="python3-wxpython"

source ../../../scripts/build-helpers

startlog

[ -f wxpython-$V.tar.gz ] || wget https://files.pythonhosted.org/packages/22/43/81657a6b126ffc19163500a8184d683cec08eb4e1d06905cd0c371c702d0/wxpython-$V.tar.gz
[ -f ../wxpython-$V/setup.py ] || {
	tar -C .. -xzf wxpython-$V.tar.gz
	rm -f patched
}
[ -f ../wxpython-$V/patched ] || {
	patch -d ../wxpython-$V -p1 --dry-run <wx.diff
	patch -d ../wxpython-$V -p1 <wx.diff >../wxpython-$V/patched
}

(
	fetchenv osgeo4w/bin/o4w_env.bat
	vsenv


	cd ../wxpython-$V

	pip install -r requirements.txt
	pip install "setuptools<81"

	export INCLUDE="$(cygpath -aw ../osgeo4w/osgeo4w/lib/vc_x64_dll/mswu);$(cygpath -aw ../osgeo4w/osgeo4w/include);$INCLUDE"
	export LIB="$(cygpath -aw ../osgeo4w/osgeo4w/lib/vc_x64_dll);$LIB"
	python3 build.py build_py --release --x64 --use_syswx --extra_waf='--msvc_version="msvc 17.14"'

	python3 build.py bdist_wheel

	# skip version check - we need old setuptools to build
	OSGEO4W_PY_SKIP_VCHECK=1 OSGEO4W_PY_INCLUDE_BINARY=1 wheel=$(cygpath -aw dist/*.whl) addsrcfiles=osgeo4w/wx.diff adddepends=wxwidgets packagewheel
)

endlog
