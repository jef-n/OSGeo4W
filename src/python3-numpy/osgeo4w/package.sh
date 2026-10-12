export P=python3-numpy
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-devel"
export PACKAGES="python3-numpy"

source ../../../scripts/build-helpers

startlog

(
	fetchenv osgeo4w/bin/o4w_env.bat

	pip3 install scipy_openblas64

	pc=osgeo4w/apps/Python*/Lib/site-packages/scipy_openblas64/lib/pkgconfig/scipy-openblas.pc
	p=$(basename "$pc" .pc)
	b=$(cygpath "$pc/../..")

	cat >osgeo4w/bin/pkg-config.bat <<EOF
@echo off
if "%1"=="--help" echo Pure-Fake
if "%1"=="--version" echo 1.0.0
if "%2"=="$p" (
        if "%1"=="--cflags" echo $(sed -ne "/Cflags: / { s/^Cflags: //; s#\${includedir}#$b/include#; p; }" $pc)
        if "%1"=="--libs" echo $(sed -ne "/Libs: / { s/^Libs: //; s#\${libdir}#$b/lib#; p; }" $pc)
        if "%1"=="--modversion" echo $(sed -ne "s/^version=//p" $pc)
        if "%1"=="--variable=bindir" echo
        if "%1"=="--variable=includedir" echo $b/include
        if "%1"=="--variable=libdir" echo $b/lib
        if "%1"=="--variable=openblas_config" echo $(sed -ne "s/openblas_config=/ /p" $pc)
        if "%1"=="--variable=pcfiledir" echo $b/lib/pkgconfig
        if "%1"=="--variable=symbol_suffix" echo
        if "%1"=="--print-variables" (
                echo extralib
                echo version
                echo openblas_config
                echo includedir
                echo libdir
                echo pcfiledir
        )
)
EOF

	s=$(cygpath -am osgeo4w/apps/$PYTHON/Lib/site-packages/scipy_openblas64/lib/libscipy_openblas64_.dll)
	d=apps/$PYTHON/Lib/site-packages/numpy/_core/libscipy_openblas64_.dll

	OSGEO4W_PY_INCLUDE_BINARY=1 \
	PIP_NO_BINARY=numpy \
	INCLUDE="$INCLUDE;$(cygpath -aw osgeo4w/apps/$PYTHON/include)" \
	LIB="$LIB;$(cygpath -aw osgeo4w/apps/$PYTHON/libs)" \
	addfiles=$s=$d \
		packagewheel \
			-Csetup-args=-Dcpu-baseline=none \
			-Csetup-args=-Dallow-noblas=false
)

endlog
