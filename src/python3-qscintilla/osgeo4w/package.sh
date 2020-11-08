export P=python3-qscintilla
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools qscintilla-devel"

source ../../../scripts/build-helpers

startlog

additionaldeps="qscintilla-libs" packagewheel

endlog
