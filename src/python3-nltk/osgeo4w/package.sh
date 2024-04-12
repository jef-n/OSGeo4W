export P=python3-nltk
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-six python3-click python3-tqdm python3-joblib python3-regex"
export PACKAGES="python3-nltk"

source ../../../scripts/build-helpers

startlog

packagewheel

endlog
