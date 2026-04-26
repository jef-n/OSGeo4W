export P=python3-pyqt6-webengine
export V=6.11.0
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-setuptools python3-devel python3-pyqt6-sip python3-pyqt6 qt6-devel"
export PACKAGES="python3-pyqt6-webengine"

source ../../../scripts/build-helpers

startlog

[ -f pyqt6_webengine-$V.tar.gz ] || wget https://files.pythonhosted.org/packages/9a/c6/b4f777c46ff42a759180dc65ad49a207748ea2e83ac4df21e89eaf4834c3/pyqt6_webengine-$V.tar.gz
[ -d ../pyqt6_webengine-$V ] || tar -C .. -xzf pyqt6_webengine-$V.tar.gz

(
        fetchenv osgeo4w/bin/o4w_env.bat
        fetchenv osgeo4w/bin/qt6_env.bat
        vsenv

        export LIB="$LIB;$(cygpath -am osgeo4w/lib)"
        export INCLUDE="$INCLUDE;$(cygpath -am osgeo4w/include)"

	rm -f *.whl
        pip wheel --no-binary=:all: --no-deps --only-binary=PyQt6-WebEngine ../pyqt6_webengine-$V
	OSGEO4W_PY_INCLUDE_BINARY=1 wheel=$(cygpath -aw *.whl) adddepends=qt6-libs packagewheel --no-binary=:all: --no-deps --no-build-isolation --force-reinstall
)

endlog
