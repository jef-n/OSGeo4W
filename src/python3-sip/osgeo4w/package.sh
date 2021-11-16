export P=python3-sip
export V=6.1.1
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="base python3-core python3-setuptools python3-wheel python3-devel"

source ../../../scripts/build-helpers

startlog

[ -f sip-$V.tar.gz ] || wget https://files.pythonhosted.org/packages/f8/b2/fcd5e964eefce0737512fb4ea263308769c671c3b1b9b1e380a5008ffef0/sip-$V.tar.gz
[ -f ../sip-$V/setup.py ] || {
	tar -C .. -xzf sip-$V.tar.gz
	rm -f patched
}
[ -f patched ] || {
	patch -d ../sip-$V -p1 --dry-run <unicode_docstrings.diff
	patch -d ../sip-$V -p1 <unicode_docstrings.diff
	touch patched
}

(
	fetchenv osgeo4w/bin/o4w_env.bat
	vs2019env

	cd ../sip-$V

	python3 setup.py build
	python3 setup.py bdist_wheel

	wheel=$(cygpath -aw dist/*.whl) addsrcfiles=osgeo4w/unicode_docstrings.diff packagewheel
)

endlog
