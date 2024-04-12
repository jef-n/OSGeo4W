export P=python3-jupyter-server
export V=pip
export B=pip
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-pip python3-wheel python3-setuptools python3-maturin python3-traitlets python3-anyio python3-argon2-cffi python3-packaging python3-websocket-client python3-nbconvert python3-jupyter-client python3-jupyter-events python3-jupyter-core python3-pyzmq python3-send2trash python3-jupyter-server-terminals python3-tornado python3-prometheus-client python3-jinja2 python3-pywinpty python3-overrides python3-nbformat python3-terminado"
export PACKAGES="python3-jupyter-server"

source ../../../scripts/build-helpers

startlog

packagewheel --only-binary :all:

endlog
