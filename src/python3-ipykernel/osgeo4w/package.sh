export P=python3-ipykernel
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-jupyter-client python3-tornado python3-traitlets python3-ipython python3-debugpy python3-jupyter-core python3-nest-asyncio python3-comm python3-pyzmq python3-matplotlib-inline python3-psutil python3-packaging"
export PACKAGES="python3-ipykernel"

source ../../../scripts/build-helpers

startlog

cat <<EOF >pip.env
unset PIP_NO_BINARY
EOF

packagewheel

endlog
